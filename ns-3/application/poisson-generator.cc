#include "poisson-generator.h"
#include "ns3/udp-socket-factory.h"
#include "ns3/socket-factory.h"
#include <random>

namespace ns3 {

NS_LOG_COMPONENT_DEFINE ("PoissonGenerator");

NS_OBJECT_ENSURE_REGISTERED (PoissonGenerator);

PoissonGenerator::PoissonGenerator() :
    m_delay (1.0),
    m_size (1400)
{
  NS_LOG_FUNCTION (this);
}

PoissonGenerator::~PoissonGenerator()
{
  NS_LOG_FUNCTION (this);
}

void 
PoissonGenerator::SetRemote (TypeId socketType, 
                            Address remote)
{
  TypeId tid = socketType;
  m_socket = Socket::CreateSocket (GetNode (), tid);
  m_socket->Bind ();
  m_socket->ShutdownRecv ();
  m_socket->Connect (remote);
}


void
PoissonGenerator::CancelEvents (void) {
    Simulator::Cancel (m_sendEvent);
}

void
PoissonGenerator::DoGenerate (void)
{
    Ptr<ExponentialRandomVariable> y = CreateObject<ExponentialRandomVariable> ();
    y->SetAttribute("Mean", DoubleValue(m_delay));
    // std::cout << y->GetValue() << std::endl;
    m_sendEvent = Simulator::Schedule (Seconds (y->GetValue()), &PoissonGenerator::DoGenerate, this);
    Ptr<Packet> p = Create<Packet> (m_size);
    m_socket->Send (p);
    std::cout << p->ToString();
}

TypeId
PoissonGenerator::GetTypeId (void)
{
  static TypeId tid = TypeId ("ns3::PoissonGenerator")
    .SetParent<Application> ()
    .SetGroupName("Applications")
    .AddConstructor<PoissonGenerator> ()
    .AddAttribute ("Delay", "The delay between two packets (s)",
					DoubleValue (0.1),
					MakeDoubleAccessor (&PoissonGenerator::m_delay),
					MakeDoubleChecker<double> ())
    .AddAttribute ("Remote", "The address of the destination",
                   AddressValue (),
                   MakeAddressAccessor (&PoissonGenerator::m_remote),
                   MakeAddressChecker ())     
    .AddAttribute ("Protocol", "The type of protocol to use. This should be "
                   "a subclass of ns3::SocketFactory",
                   TypeIdValue (UdpSocketFactory::GetTypeId ()),
                   MakeTypeIdAccessor (&PoissonGenerator::m_protocol),
                   // This should check for SocketFactory as a parent
                   MakeTypeIdChecker ())                 
    .AddAttribute ("PacketSize", "The size of each packet (bytes)",
                    UintegerValue (1400),
                    MakeUintegerAccessor (&PoissonGenerator::m_size),
                    MakeUintegerChecker<uint32_t> ())
    ;
  return tid;
} 

void
PoissonGenerator::StartApplication ()
{
    SetRemote(m_protocol, m_remote);
    DoGenerate();
}

void
PoissonGenerator::StopApplication ()
{
  NS_LOG_FUNCTION (this);

  if(m_socket != 0)
    {
      m_socket->Close ();
    }
  else
    {
      NS_LOG_WARN ("OnOffApplication found null socket to close in StopApplication");
    }
}

PoissonAppHelper::PoissonAppHelper (std::string protocol, Address address, double delay, uint32_t packageSize)
{
  m_factory.SetTypeId ("ns3::PoissonGenerator");
  m_factory.Set ("Protocol", StringValue (protocol));
  m_factory.Set ("Remote", AddressValue (address));
  m_factory.Set ("Delay", DoubleValue(delay));
  m_factory.Set ("PacketSize", UintegerValue (packageSize));
}

void 
PoissonAppHelper::SetAttribute (std::string name, const AttributeValue &value)
{
  m_factory.Set (name, value);
}

ApplicationContainer 
PoissonAppHelper::Install (NodeContainer nodes)
{
  ApplicationContainer applications;
  for (NodeContainer::Iterator i = nodes.Begin (); i != nodes.End (); ++i)
    {
      Ptr<PoissonGenerator> app = m_factory.Create<PoissonGenerator> ();
      (*i)->AddApplication (app);
      applications.Add (app);
    }
  return applications;
}
}