#ifndef MESSAGE_QUEUE_H
#define MESSAGE_QUEUE_H

#include "Arduino.h"
#include "../config.h"

/*
 * Message Queue for Buffering Messages
 * Thread-safe circular buffer for storing messages
 */

class MessageQueue {
public:
    MessageQueue(size_t capacity = MESSAGE_QUEUE_SIZE);
    ~MessageQueue();
    
    // Queue operations
    bool enqueue(const String& message);
    bool dequeue(String& message);
    String dequeue(); // Alternative that returns String directly
    
    // Queue status
    bool isEmpty() const;
    bool isFull() const;
    size_t size() const;
    size_t capacity() const { return maxSize; }
    size_t available() const { return maxSize - currentSize; }
    
    // Queue management
    void clear();
    bool peek(String& message) const; // Look at next message without removing
    
    // Statistics
    unsigned long getTotalEnqueued() const { return totalEnqueued; }
    unsigned long getTotalDequeued() const { return totalDequeued; }
    unsigned long getOverflows() const { return overflowCount; }
    
    // Configuration
    void setCapacity(size_t newCapacity);
    
private:
    String* buffer;
    size_t maxSize;
    size_t currentSize;
    size_t head;
    size_t tail;
    
    // Statistics
    unsigned long totalEnqueued;
    unsigned long totalDequeued;
    unsigned long overflowCount;
    
    // Internal methods
    size_t nextIndex(size_t index) const;
    bool resize(size_t newCapacity);
};

#endif // MESSAGE_QUEUE_H 