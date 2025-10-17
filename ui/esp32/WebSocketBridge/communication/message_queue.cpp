#include "message_queue.h"
#include "../utils/debug_utils.h"

MessageQueue::MessageQueue(size_t capacity) :
    buffer(nullptr),
    maxSize(capacity),
    currentSize(0),
    head(0),
    tail(0),
    totalEnqueued(0),
    totalDequeued(0),
    overflowCount(0)
{
    buffer = new String[maxSize];
    if (!buffer) {
        DEBUG_ERROR("MessageQueue", "Failed to allocate buffer memory");
        maxSize = 0;
    }
}

MessageQueue::~MessageQueue() {
    if (buffer) {
        delete[] buffer;
        buffer = nullptr;
    }
}

bool MessageQueue::enqueue(const String& message) {
    if (!buffer || message.length() == 0) {
        return false;
    }
    
    if (isFull()) {
        DEBUG_WARNING("MessageQueue", "Queue full, dropping oldest message");
        overflowCount++;
        
        // Remove oldest message to make room
        String dummy;
        dequeue(dummy);
    }
    
    buffer[tail] = message;
    tail = nextIndex(tail);
    currentSize++;
    totalEnqueued++;
    
    return true;
}

bool MessageQueue::dequeue(String& message) {
    if (isEmpty()) {
        return false;
    }
    
    message = buffer[head];
    buffer[head] = ""; // Clear the slot
    head = nextIndex(head);
    currentSize--;
    totalDequeued++;
    
    return true;
}

String MessageQueue::dequeue() {
    String message;
    if (dequeue(message)) {
        return message;
    }
    return "";
}

bool MessageQueue::isEmpty() const {
    return currentSize == 0;
}

bool MessageQueue::isFull() const {
    return currentSize >= maxSize;
}

size_t MessageQueue::size() const {
    return currentSize;
}

void MessageQueue::clear() {
    if (buffer) {
        for (size_t i = 0; i < maxSize; i++) {
            buffer[i] = "";
        }
    }
    
    head = 0;
    tail = 0;
    currentSize = 0;
}

bool MessageQueue::peek(String& message) const {
    if (isEmpty()) {
        return false;
    }
    
    message = buffer[head];
    return true;
}

void MessageQueue::setCapacity(size_t newCapacity) {
    if (newCapacity == maxSize || newCapacity == 0) {
        return;
    }
    
    resize(newCapacity);
}

size_t MessageQueue::nextIndex(size_t index) const {
    return (index + 1) % maxSize;
}

bool MessageQueue::resize(size_t newCapacity) {
    if (newCapacity == 0) {
        DEBUG_ERROR("MessageQueue", "Cannot resize to zero capacity");
        return false;
    }
    
    // Create new buffer
    String* newBuffer = new String[newCapacity];
    if (!newBuffer) {
        DEBUG_ERROR("MessageQueue", "Failed to allocate new buffer");
        return false;
    }
    
    // Copy existing messages to new buffer
    size_t copyCount = min(currentSize, newCapacity);
    for (size_t i = 0; i < copyCount; i++) {
        newBuffer[i] = buffer[(head + i) % maxSize];
    }
    
    // Update overflow count if we're losing messages
    if (currentSize > newCapacity) {
        overflowCount += (currentSize - newCapacity);
    }
    
    // Replace old buffer
    delete[] buffer;
    buffer = newBuffer;
    maxSize = newCapacity;
    currentSize = copyCount;
    head = 0;
    tail = copyCount % maxSize;
    
    DEBUG_INFO("MessageQueue", "Resized to " + String(newCapacity) + " capacity");
    return true;
} 