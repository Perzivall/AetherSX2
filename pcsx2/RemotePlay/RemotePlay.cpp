#include "RemotePlay.h"
#include "../../3rdparty/jpgd/jpge.h"
#include <iostream>
#include <string>
#include <cstring>
#include <sstream>

#if defined(_WIN32)
// Windows socket includes
#else
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <android/log.h>
#include <errno.h>
#endif

namespace Aether {

RemotePlay& RemotePlay::Get() {
    static RemotePlay instance;
    return instance;
}

RemotePlay::RemotePlay() : m_running(false), m_active(false), m_serverSocket(-1), m_hasNewFrame(false), m_port(8080) {}

RemotePlay::~RemotePlay() {
    Stop();
}

void RemotePlay::Start(int port) {
    if (m_running) return;
    m_port = port;
    m_running = true;
    m_thread = std::thread(&RemotePlay::ServerLoop, this);
    m_active = true;
}

void RemotePlay::Stop() {
    m_running = false;
    m_active = false;
    if (m_serverSocket != -1) {
        close(m_serverSocket);
        m_serverSocket = -1;
    }
    if (m_thread.joinable()) {
        m_thread.join();
    }
}

// Helper to convert RGBA to RGB
void ConvertRGBAtoRGB(const std::vector<unsigned int>& src, int width, int height, std::vector<unsigned char>& dst) {
    if (src.size() < (size_t)(width * height)) return;
    dst.resize(width * height * 3);
    const unsigned char* srcPtr = (const unsigned char*)src.data();
    unsigned char* dstPtr = dst.data();
    
    for (int i = 0; i < width * height; ++i) {
        dstPtr[0] = srcPtr[0]; // R
        dstPtr[1] = srcPtr[1]; // G
        dstPtr[2] = srcPtr[2]; // B
        dstPtr += 3;
        srcPtr += 4;
    }
}

void RemotePlay::Frame(int width, int height, const std::vector<unsigned int>& data) {
    if (!m_running) return;
    
    // Quick downsample or direct compress
    
    static std::vector<unsigned char> rgbData;
    ConvertRGBAtoRGB(data, width, height, rgbData);
    
    // JPGE
    int buf_size = width * height * 3; 
    if (buf_size < 1024) buf_size = 1024;
    
    static std::vector<unsigned char> tempJpeg;
    if (tempJpeg.size() < (size_t)buf_size) tempJpeg.resize(buf_size);
    
    jpge::params params;
    params.m_quality = 65; // Low quality for speed
    params.m_subsampling = jpge::H2V2;
    
    if (jpge::compress_image_to_jpeg_file_in_memory(tempJpeg.data(), buf_size, width, height, 3, rgbData.data(), params)) {
        std::lock_guard<std::mutex> lock(m_frameMutex);
        m_jpegBuffer.assign(tempJpeg.begin(), tempJpeg.begin() + buf_size);
        m_width = width;
        m_height = height;
        m_hasNewFrame = true;
    }
}

void RemotePlay::ServerLoop() {
    m_serverSocket = socket(AF_INET, SOCK_STREAM, 0);
    if (m_serverSocket < 0) {
        __android_log_print(ANDROID_LOG_ERROR, "AetherRemote", "Socket creation failed: %s", strerror(errno));
        return;
    }
    
    int opt = 1;
    setsockopt(m_serverSocket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    
    struct sockaddr_in address;
    memset(&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(m_port);
    
    if (bind(m_serverSocket, (struct sockaddr*)&address, sizeof(address)) < 0) {
        __android_log_print(ANDROID_LOG_ERROR, "AetherRemote", "Bind failed on port %d: %s", m_port, strerror(errno));
        close(m_serverSocket);
        return;
    }
    
    if (listen(m_serverSocket, 3) < 0) {
        __android_log_print(ANDROID_LOG_ERROR, "AetherRemote", "Listen failed: %s", strerror(errno));
        close(m_serverSocket);
        return;
    }

    __android_log_print(ANDROID_LOG_INFO, "AetherRemote", "Server listening on port %d", m_port);
    
    while (m_running) {
        struct sockaddr_in clientAddr;
        socklen_t clientLen = sizeof(clientAddr);
        int clientSocket = accept(m_serverSocket, (struct sockaddr*)&clientAddr, &clientLen);
        if (clientSocket < 0) {
            if (m_running) {
                 __android_log_print(ANDROID_LOG_ERROR, "AetherRemote", "Accept failed: %s", strerror(errno));
                 continue; 
            }
            else break;
        }
        
        char clientIP[INET_ADDRSTRLEN];
        inet_ntop(AF_INET, &(clientAddr.sin_addr), clientIP, INET_ADDRSTRLEN);
        __android_log_print(ANDROID_LOG_INFO, "AetherRemote", "Client connected from %s", clientIP);

        std::thread([this, clientSocket]() {
            this->HandleClient(clientSocket);
        }).detach();
    }
}

void RemotePlay::HandleClient(int clientSocket) {
    char buffer[1024] = {0};
    ssize_t read_bytes = read(clientSocket, buffer, 1023);
    if (read_bytes <= 0) {
        close(clientSocket);
        return;
    }
    
    std::string request(buffer);
    if (request.find("GET /stream") != std::string::npos) {
        std::string response = "HTTP/1.1 200 OK\r\n"
                               "Content-Type: multipart/x-mixed-replace; boundary=frame\r\n"
                               "\r\n";
        send(clientSocket, response.c_str(), response.length(), MSG_NOSIGNAL);
        
        while (m_running) {
            std::vector<unsigned char> currentFrame;
            {
                std::lock_guard<std::mutex> lock(m_frameMutex);
                if (m_hasNewFrame) {
                    currentFrame = m_jpegBuffer;
                }
            }
            
            if (!currentFrame.empty()) {
                std::stringstream ss;
                ss << "--frame\r\n";
                ss << "Content-Type: image/jpeg\r\n";
                ss << "Content-Length: " << currentFrame.size() << "\r\n";
                ss << "\r\n";
                
                std::string header = ss.str();
                if (send(clientSocket, header.c_str(), header.length(), MSG_NOSIGNAL) < 0) break;
                if (send(clientSocket, currentFrame.data(), currentFrame.size(), MSG_NOSIGNAL) < 0) break;
                if (send(clientSocket, "\r\n", 2, MSG_NOSIGNAL) < 0) break;
            }
            
            std::this_thread::sleep_for(std::chrono::milliseconds(30)); // Cap approx 30 FPS
        }
    } else {
        std::string response = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n"
                               "<html><head><title>Aether Remote</title></head>"
                               "<body style='background:black; color:white; text-align:center;'>"
                               "<h1>AetherSX2 Remote Console</h1>"
                               "<img src='/stream' style='width:90%; height:auto; border: 2px solid white;'/>"
                               "</body></html>";
        send(clientSocket, response.c_str(), response.length(), MSG_NOSIGNAL);
    }
    
    close(clientSocket);
}

}
