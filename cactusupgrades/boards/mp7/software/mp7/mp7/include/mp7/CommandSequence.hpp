
#ifndef __MP7_COMMANDSEQUENCE_HPP__
#define __MP7_COMMANDSEQUENCE_HPP__

#include <stdint.h>
#include <vector>
#include <string>
#include <deque>
#include <ostream>

#include <boost/noncopyable.hpp>
#include <boost/ptr_container/ptr_deque.hpp>
// Forward declaration
namespace uhal {

class Node;
class HwInterface;

} // uhal


namespace mp7 {


struct Transaction {
    const uhal::Node* mNode;
    virtual ~Transaction() {}
    
    virtual void execute() const = 0;

    virtual Transaction* clone() const = 0;

    virtual void stream(std::ostream& os) const = 0;
    
};

Transaction* new_clone( const Transaction& lOriginal );


struct WriteTransaction : public Transaction {
    uint32_t mValue;
    virtual ~WriteTransaction() {}
    
    virtual void execute() const;


    virtual WriteTransaction* clone() const;

    void stream(std::ostream& os) const;

};

struct WriteBlockTransaction : public Transaction {
    std::vector<uint32_t> mBlock;
    virtual ~WriteBlockTransaction() {}

    virtual void execute() const;

    virtual WriteBlockTransaction* clone() const;
    
    void stream(std::ostream& os) const;

};


class TransactionQueue {
public:
    TransactionQueue( uhal::HwInterface& );
    ~TransactionQueue();

    void write( const uhal::Node& aNode, uint32_t aValue );
    void writeBlock( const uhal::Node& aNode, const std::vector<uint32_t> aBlock );

    void execute();
    void clear();
private:
    void throwIfWrongInterface( const uhal::Node& aNode ) const;
    
    uhal::HwInterface* mHwInterface;
    boost::ptr_deque<Transaction> mElements;
    
    friend std::ostream& operator<<( std::ostream& out, TransactionQueue& aMacro );
};


std::ostream& operator<<( std::ostream& out, Transaction& aElement );
std::ostream& operator<<( std::ostream& out, TransactionQueue& aMacro );

} // namespace mp7

#endif /* __MP7_COMMANDSEQUENCE_HPP__ */