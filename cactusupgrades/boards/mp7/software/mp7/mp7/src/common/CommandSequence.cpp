/**
 * 
 */

#include "mp7/CommandSequence.hpp"

//#include <boost/foreach.hpp>

#include <uhal/Node.hpp>
#include <uhal/HwInterface.hpp>

// MP7 Headers
#include "mp7/exception.hpp"
#include "mp7/Logger.hpp"
#include "mp7/Utilities.hpp"

// Namespace resolution
namespace l7 = mp7::logger;

namespace mp7 {

Transaction* new_clone( const Transaction& lOriginal ) {
  return lOriginal.clone();
}

void WriteTransaction::execute() const
{
  mNode->write(mValue);
}


WriteTransaction* WriteTransaction::clone() const
{
  WriteTransaction* lClone = new WriteTransaction();
  lClone->mNode = mNode;
  lClone->mValue = mValue;
  return lClone;
}

void WriteTransaction::stream(std::ostream& os) const
{
  os << mNode->getPath() << ": " << mValue;
}


void WriteBlockTransaction::execute() const
{
  mNode->writeBlock(mBlock);
}


WriteBlockTransaction* WriteBlockTransaction::clone() const
{
  WriteBlockTransaction* lClone = new WriteBlockTransaction();
  lClone->mNode = mNode;
  lClone->mBlock = mBlock;
  return lClone;

}


void WriteBlockTransaction::stream(std::ostream& os) const
{
  os << mNode->getPath() << ": Block(" << mBlock.size() << ")";
}


TransactionQueue::TransactionQueue(uhal::HwInterface& aHwInterface) : mHwInterface(&aHwInterface)
{

}


void
TransactionQueue::throwIfWrongInterface(const uhal::Node& aNode) const
{
  if (&(aNode.getClient()) != &(mHwInterface->getClient())) {
    mp7::MP7HelperException lExc(std::string("Node ") + aNode.getPath() + " doesn't seem to belong to " + mHwInterface->uri());
    MP7_LOG(l7::kError) << lExc.what();
    throw lExc;
  }
}


TransactionQueue::~TransactionQueue()
{
  this->clear();
}


void
TransactionQueue::write(const uhal::Node& aNode, uint32_t aValue)
{
  this->throwIfWrongInterface(aNode);

  WriteTransaction* e = new WriteTransaction();
  // strip the "TOP." from the beginning of the path
  //    e->mPath = aNode.getPath().substr(4);
  e->mNode = &aNode;
  e->mValue = aValue;
  mElements.push_back(e);
}


void
TransactionQueue::writeBlock(const uhal::Node& aNode, const std::vector<uint32_t> aBlock)
{
  this->throwIfWrongInterface(aNode);

  WriteBlockTransaction* e = new WriteBlockTransaction();
  // strip the "TOP." from the beginning of the path
  //    e->mPath = aNode.getPath().substr(4);
  e->mNode = &aNode;
  e->mBlock = aBlock;
  mElements.push_back(e);

}


void
TransactionQueue::execute()
{


  for(const Transaction& e :  mElements)
  {
    e.execute();
  }

  mHwInterface->getClient().dispatch();

}


void
TransactionQueue::clear()
{
  mElements.clear();
}


std::ostream& operator<<(std::ostream& out, Transaction& aElement)
{
  aElement.stream(out);
  return out;
}


std::ostream& operator<<(std::ostream& out, TransactionQueue& aMacro)
{


  for(Transaction& e :  aMacro.mElements)
  {
    out << " - " << e << std::endl;
  }

  return out;
}

} // namespace mp7
