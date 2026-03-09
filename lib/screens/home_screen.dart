import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show rootBundle, PlatformException;
import '../main.dart';
import '../models/vpn_config.dart';
import '../services/vpn_engine.dart';
import '../widgets/home_card.dart';
import '../models/vpn_status.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _vpnState = VpnEngine.vpnDisconnected;
  List<VpnConfig> _listVpn = [];
  VpnConfig? _selectedVpn;

  @override
  void initState() {
    super.initState();

    ///Add listener to update vpn state
    VpnEngine.vpnStageSnapshot().listen((event) {
      setState(() => _vpnState = event);
    });

    initVpn();
  }

  void initVpn() async {
    //sample vpn config file (you can get more from https://www.vpngate.net/)
    _listVpn.add(
      VpnConfig(
        config: await rootBundle.loadString('assets/vpn/japan.ovpn'),
        country: 'Japan',
        username: 'vpn',
        password: 'vpn',
      ),
    );

    _listVpn.add(
      VpnConfig(
        config: await rootBundle.loadString('assets/vpn/thailand.ovpn'),
        country: 'Thailand',
        username: 'vpn',
        password: 'vpn',
      ),
    );

    SchedulerBinding.instance.addPostFrameCallback(
      (t) => setState(() => _selectedVpn = _listVpn.first),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      //app bar
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        foregroundColor: Colors.white,
        title: Text('VPN'),
        actions: [
          IconButton(
            padding: EdgeInsets.only(right: 8),
            onPressed: () {},
            icon: Icon(CupertinoIcons.info, size: 27),
          ),
        ],
      ),

      //body
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Dynamic VPN Button
          _vpnButton(),

          // 2. Country & Ping Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HomeCard(
                title: _selectedVpn?.country ?? 'Select Country',
                subtitle: 'FREE',
                icon: const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF1B1B1B),
                  child: Icon(
                    Icons.vpn_lock_rounded,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
              const HomeCard(
                title: '100 ms', // You can later add logic to ping the server
                subtitle: 'PING',
                icon: CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF1B1B1B),
                  child: Icon(
                    Icons.equalizer_rounded,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          // 3. REAL-TIME SPEED ROW (Using StreamBuilder)
          StreamBuilder<VpnStatus?>(
            stream: VpnEngine.vpnStatusSnapshot(),
            builder: (context, snapshot) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HomeCard(
                    title: snapshot.data?.byteIn ?? '0 kbps',
                    subtitle: 'DOWNLOAD',
                    icon: const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFF1B1B1B),
                      child: Icon(
                        Icons.arrow_downward_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  HomeCard(
                    title: snapshot.data?.byteOut ?? '0 kbps',
                    subtitle: 'UPLOAD',
                    icon: const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFF1B1B1B),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _connectClick() async {
    print("Connect Clicked! Selected VPN: ${_selectedVpn?.country}");
    if (_selectedVpn == null) return;

    try {
      if (_vpnState == VpnEngine.vpnDisconnected) {
        await VpnEngine.startVpn(_selectedVpn!);
      } else {
        await VpnEngine.stopVpn();
      }
    } on PlatformException catch (e) {
      print("NATIVE ERROR: ${e.message}");
      print("DETAILS: ${e.details}");
    } catch (e) {
      print("FLUTTER ERROR: $e");
    }
  }

  //vpn button
  Widget _vpnButton() => Column(
    children: [
      Semantics(
        button: true,
        child: InkWell(
          onTap: () => _connectClick(),
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Change outer glow color based on state
              color: _getButtonColor().withOpacity(0),
            ),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getButtonColor().withOpacity(1),
              ),
              child: Container(
                width: mq.height * .14,
                height: mq.height * .14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getButtonColor(), // Main button color
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.power_settings_new,
                      size: 28,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _vpnState == VpnEngine.vpnDisconnected
                          ? 'Tap to Connect'
                          : _vpnState.replaceAll('_', ' ').toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      // Connection status label below the button
      Container(
        margin: EdgeInsets.only(top: mq.height * .015, bottom: mq.height * .02),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        decoration: BoxDecoration(
          color: _getButtonColor(),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          _vpnState == VpnEngine.vpnDisconnected
              ? 'Not Connected'
              : _vpnState.replaceAll('_', ' ').toUpperCase(),
          style: const TextStyle(fontSize: 12.5, color: Colors.white),
        ),
      ),
    ],
  );

  Color _getButtonColor() {
    switch (_vpnState) {
      case VpnEngine.vpnConnected:
        return Colors.green;
      case VpnEngine.vpnConnecting:
      case VpnEngine.vpnAuthenticating:
        return Colors.orange;
      case VpnEngine.vpnWaitConnection:
        return Colors.blue;
      default:
        return const Color(0xFF1B1B1B);
    }
  }
}

//  Center(
//           child: TextButton(
//             style: TextButton.styleFrom(
//               shape: StadiumBorder(),
//               backgroundColor: Theme.of(context).primaryColor,
//             ),
//             child: Text(
//               _vpnState == VpnEngine.vpnDisconnected
//                   ? 'Connect VPN'
//                   : _vpnState.replaceAll("_", " ").toUpperCase(),
//               style: TextStyle(color: Colors.white),
//             ),
//             onPressed: _connectClick,
//           ),
//         ),
//         StreamBuilder<VpnStatus?>(
//           initialData: VpnStatus(),
//           stream: VpnEngine.vpnStatusSnapshot(),
//           builder: (context, snapshot) => Text(
//               "${snapshot.data?.byteIn ?? ""}, ${snapshot.data?.byteOut ?? ""}",
//               textAlign: TextAlign.center),
//         ),

//         //sample vpn list
//         Column(
//             children: _listVpn
//                 .map(
//                   (e) => ListTile(
//                     title: Text(e.country),
//                     leading: SizedBox(
//                       height: 20,
//                       width: 20,
//                       child: Center(
//                           child: _selectedVpn == e
//                               ? CircleAvatar(backgroundColor: Colors.green)
//                               : CircleAvatar(backgroundColor: Colors.grey)),
//                     ),
//                     onTap: () {
//                       log("${e.country} is selected");
//                       setState(() => _selectedVpn = e);
//                     },
//                   ),
//                 )
//                 .toList())
