#pragma once
#include <vector>
#include <mutex>
#include <thread>
#include <atomic>

namespace Aether {

class RemotePlay {
public:
    static RemotePlay& Get();
    
    // Call this from the GS Thread
    // data is expected to be RGBA (32-bit)
    void Frame(int width, int height, const std::vector<unsigned int>& data);
    
    // Start/Stop Server
    void Start(int port);
    void Stop();
    
    bool IsActive() const { return m_active; }

private:
    RemotePlay();
    ~RemotePlay();
    
    void ServerLoop();
    void HandleClient(int clientSocket);
    
    std::atomic<bool> m_running;
    std::atomic<bool> m_active;
    int m_serverSocket;
    int m_port;
    std::thread m_thread;
    
    // Frame Buffer
    std::mutex m_frameMutex;
    std::vector<unsigned char> m_jpegBuffer;
    int m_width;
    int m_height;
    bool m_hasNewFrame;
};

}
