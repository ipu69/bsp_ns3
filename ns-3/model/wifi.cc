#include "ns3/command-line.h"
#include "ns3/config.h"
#include "ns3/uinteger.h"
#include "ns3/boolean.h"
#include "ns3/config.h"
#include "ns3/integer.h"
#include "ns3/string.h"
#include "ns3/yans-wifi-helper.h"
#include "ns3/internet-stack-helper.h"
#include "ns3/ipv4-address-helper.h"
#include "ns3/udp-echo-helper.h"
#include "ns3/yans-wifi-channel.h"
#include "ns3/constant-position-mobility-model.h"
#include "ns3/propagation-loss-model.h"
#include "ns3/propagation-delay-model.h"
#include "ns3/on-off-helper.h"
#include "ns3/flow-monitor-helper.h"
#include "ns3/ipv4-flow-classifier.h"
#include "ns3/aodv-module.h"
#include "ns3/poisson-generator.h"
#include "ns3/mobility-helper.h"
#include "ns3/random-variable-stream.h"
#include "ns3/rng-seed-manager.h"
#include <ctime>
#include <chrono>

/**
 * Topology: [node 0] <-- -50 dB --> [node 1]<-- -50db - --> .... <-- -50 dB --> [node stationsNumber - 1]
 */


using namespace ns3;

int placements[5] =
        {29, 40, 181, 273, 300};

int p_tr[5] =
        {-67, -67, -67, -67, -69};

int g_tr[5] = {5, 5, 5, 5, 5};

void
experiment(uint32_t stationsNumber, uint32_t simulationTime) {
    RngSeedManager::SetSeed(time(0));

    // Nodes creation
    NodeContainer nodes;
    nodes.Create(stationsNumber);

    // Stations placement
    MobilityHelper mobility;
    Ptr <ListPositionAllocator> positionAlloc = CreateObject<ListPositionAllocator>();
    mobility.SetMobilityModel("ns3::ConstantPositionMobilityModel");

    for (uint32_t i = 0; i < stationsNumber; i++) {
        positionAlloc->Add(Vector(placements[i], 0.0, 0.0));
    }

    mobility.SetPositionAllocator(positionAlloc);
    mobility.Install(nodes);

    // Channels matrix

    Ptr <MatrixPropagationLossModel> lossModel = CreateObject<MatrixPropagationLossModel>();
    lossModel->SetDefaultLoss(2000);

    for (uint32_t i = 0; i < stationsNumber - 1; i++) {
        lossModel->SetLoss(nodes.Get(i)->GetObject<MobilityModel>(), nodes.Get(i + 1)->GetObject<MobilityModel>(),
                           5);
    }

    Ptr <YansWifiChannel> wifiChannel = CreateObject<YansWifiChannel>();
    wifiChannel->SetPropagationLossModel(lossModel);
    wifiChannel->SetPropagationDelayModel(CreateObject<ConstantSpeedPropagationDelayModel>());

    // Wi-Fi configuration
    WifiHelper wifi;
    wifi.SetRemoteStationManager("ns3::IdealWifiManager");
    wifi.SetStandard(WIFI_STANDARD_80211n_2_4GHZ);
    YansWifiPhyHelper wifiPhy = YansWifiPhyHelper::Default();

    // Set phy parameters
    wifiPhy.Set("RxGain", DoubleValue(5));
    wifiPhy.Set("Antennas", UintegerValue(2));
    wifiPhy.Set("TxPowerStart", DoubleValue(20));
    wifiPhy.Set("TxPowerEnd", DoubleValue(20));

    wifiPhy.SetChannel(wifiChannel);
    WifiMacHelper wifiMac;
    wifiMac.SetType("ns3::AdhocWifiMac");

    NetDeviceContainer devices = wifi.Install(wifiPhy, wifiMac, nodes);

    // TCP-IP
    AodvHelper aodv;
    InternetStackHelper internet;
    internet.SetRoutingHelper(aodv);
    internet.Install(nodes);
    Ipv4AddressHelper ipv4;
    ipv4.SetBase("10.0.0.0", "255.0.0.0");
    Ipv4InterfaceContainer wifiInterfaces;
    wifiInterfaces = ipv4.Assign(devices);

    uint32_t payloadSize = 1472; //bytes
    double delay = 0.02;
    uint16_t port = 5001;

    InetSocketAddress destA(wifiInterfaces.GetAddress(stationsNumber - 1), port);
    PoissonAppHelper app("ns3::UdpSocketFactory", destA, delay, payloadSize);

    for (uint32_t i = 0; i < stationsNumber - 1; ++i) {
        ApplicationContainer clientAppA = app.Install(nodes.Get(i));
        clientAppA.Start(Seconds(1.0));
        clientAppA.Stop(Seconds(simulationTime));
    }

    // FlowMonitor
    FlowMonitorHelper flowmon;
    Ptr <FlowMonitor> monitor = flowmon.InstallAll();
    //internet.EnablePcapIpv4All("wifi-aodv.tr");

    Simulator::Stop(Seconds(simulationTime));
    auto start = std::chrono::system_clock::now();
    Simulator::Run();

    // 10. Print per flow statistics
    monitor->CheckForLostPackets();
    Ptr <Ipv4FlowClassifier> classifier = DynamicCast<Ipv4FlowClassifier>(flowmon.GetClassifier());
    FlowMonitor::FlowStatsContainer stats = monitor->GetFlowStats();
    for (std::map<FlowId, FlowMonitor::FlowStats>::const_iterator i = stats.begin(); i != stats.end(); ++i) {
        Ipv4FlowClassifier::FiveTuple t = classifier->FindFlow(i->first);
        std::cout << "Flow " << i->first << " (" << t.sourceAddress << " -> " << t.destinationAddress << ")\n";
        std::cout << "Tx Packets: " << i->second.txPackets << std::endl;
        std::cout << "Tx Bytes:   " << i->second.txBytes << std::endl;
        std::cout << "Rx Packets: " << i->second.rxPackets << std::endl;
        std::cout << "Delay: " << i->second.delaySum.GetSeconds() / i->second.rxPackets << std::endl;
        std::cout << "Rx Bytes:   " << i->second.rxBytes << std::endl;
        std::cout << "Throughput: " << i->second.rxBytes * 8.0 / simulationTime / 1000 / 1000 << " Mbps" << std::endl;;
        std::cout << "Lost Packets: " << i->second.lostPackets << std::endl;
        std::cout << "Lost Probability: " << i->second.lostPackets * 1.0 / i->second.rxPackets << std::endl;
    }

    auto end = std::chrono::system_clock::now();
    std::chrono::duration<double> elapsed_seconds = end - start;

    std::cout << "elapsed time: " << elapsed_seconds.count() << "s\n";

    Simulator::Destroy();
}

int
main(int argc, char **argv) {
    std::string wifiManager("Aarf");
    CommandLine cmd;
    cmd.AddValue(
            "wifiManager",
            "Set wifi rate manager (Aarf, Aarfcd, Amrr, Arf, Cara, Ideal, Minstrel, Onoe, Rraa)",
            wifiManager);
    cmd.Parse(argc, argv);

    experiment(5, 2000);

    return 0;
}
