#include "ns3/command-line.h"
#include "ns3/log.h"
#include "ns3/simulator.h"
#include "ns3/string.h"
#include "ns3/pointer.h"
#include "ns3/application.h"
#include "ns3/random-variable-stream.h"
#include "ns3/socket.h"
#include "ns3/simulator.h"
#include "ns3/uinteger.h"
#include "ns3/double.h"
#include "ns3/application-container.h"
#include "ns3/node-container.h"

namespace ns3 {

class PoissonGenerator : public Application
{
public:
  static TypeId GetTypeId (void);

  PoissonGenerator ();
  virtual ~PoissonGenerator();
  void SetDelay (double delay);
  void SetSize (uint32_t size);
  void SetRemote (TypeId socketType, Address remote);


private:
  virtual void StartApplication (void);
  virtual void StopApplication (void);
  void DoGenerate (void);
  void CancelEvents ();

  double m_delay;
  uint32_t m_size;
  TypeId m_protocol;   
  Address m_remote;
  Ptr<Socket> m_socket;
  EventId m_sendEvent;
};  

class PoissonAppHelper
{
public:
  PoissonAppHelper (std::string protocol, Address remote, double delay, uint32_t packageSize);
  void SetAttribute (std::string name, const AttributeValue &value);
  ApplicationContainer Install (NodeContainer c);
private:
  std::string m_protocol;
  std::string m_socketType;
  Address m_remote;
  ObjectFactory m_factory;
};
}