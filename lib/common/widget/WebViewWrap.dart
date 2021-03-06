import 'dart:io';

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wan_android/common/route/RouteManager.dart';
import 'package:wan_android/common/utils/AppBarUtils.dart';
import 'package:wan_android/common/utils/AppToastUtils.dart';
import 'package:wan_android/res/AppColors.dart';
import 'package:wan_android/res/Style.dart';

/// @Description: 全局通用WebView
/// @Author: SWY
/// @Date: 2021/2/5 21:56
class WebViewWrap extends StatefulWidget {
  final url;
  final arguments;

  WebViewWrap({Key key, this.url, this.arguments}) : super(key: key);

  @override
  _WebViewWrapState createState() =>
      _WebViewWrapState(url: this.url, title: arguments["title"]);
}

class _WebViewWrapState extends State<WebViewWrap> {
  InAppWebViewController webView;
  ContextMenu contextMenu;
  ColorsAnimation animation;
  String url;
  String title;
  double progress = 0;

  AppBar appBar;

  _WebViewWrapState({this.url, this.title});

  @override
  void initState() {
    super.initState();
    contextMenu = ContextMenu(
        menuItems: [
          ContextMenuItem(
              androidId: 1,
              iosId: "1",
              title: "Special",
              action: () async {
                print("Menu item Special clicked!");
              })
        ],
        onCreateContextMenu: (hitTestResult) async {
          print("onCreateContextMenu");
          print(hitTestResult.extra);
          print(await webView?.getSelectedText());
        },
        onHideContextMenu: () {
          print("onHideContextMenu");
        },
        onContextMenuActionItemClicked: (contextMenuItemClicked) {
          var id = (Platform.isAndroid)
              ? contextMenuItemClicked.androidId
              : contextMenuItemClicked.iosId;
          print("onContextMenuActionItemClicked: " +
              id.toString() +
              " " +
              contextMenuItemClicked.title);
        });
    animation = ColorsAnimation(progress: progress);
  }

  @override
  Widget build(BuildContext context) {
    appBar = AppBar(
      leading: ElevatedButton(
        style: Style.transButtonStyle,
        child: Icon(
          Icons.keyboard_arrow_left_sharp,
          color: AppColors.comIconColor,
        ),
        onPressed: () {
          RouteManager.finish(context);
        },
      ),
      title: Text(title,
          overflow: TextOverflow.fade, style: TextStyle(fontSize: 16)),
      actions: [
        Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
            child: ElevatedButton(
              style: Style.transButtonStyle,
              child: Icon(
                Icons.more_vert,
                color: AppColors.comIconColor,
              ),
              onPressed: () {
                showMenuClick();
              },
            )),
      ],
    );
    return WillPopScope(
        child: Scaffold(
          appBar: appBar,
          body: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: 1,
                heightFactor: 1,
                child: _getWebView(),
              ),
              _getIndicatorBar()
            ],
          ),
        ),
        onWillPop: () {
          webView.canGoBack().then((value) {
            if (value)
              webView.goBack();
            else
              RouteManager.finish(context);
          });

          return null;
        });
  }

  InAppWebView _getWebView() {
    return InAppWebView(
      initialUrl: url,
      // contextMenu: contextMenu,
      initialHeaders: {},
      initialOptions: InAppWebViewGroupOptions(
          crossPlatform:
              InAppWebViewOptions(useShouldOverrideUrlLoading: true)),
      onWebViewCreated: (InAppWebViewController controller) {
        webView = controller;
      },
      onTitleChanged: (controller, title) {
        setState(() {
          this.title = title;
        });
      },
      onLoadStart: (controller, url) {
        setState(() {
          this.url = url ?? '';
        });
      },
      onLoadStop: (controller, url) async {
        setState(() {
          this.url = url ?? '';
        });
      },
      onProgressChanged: (controller, progress) {
        setState(() {
          this.progress = progress / 100;
          animation.updateValues(this.progress);
        });
      },
      shouldOverrideUrlLoading: (controller, shouldOverrideUrlLoadingRequest) {
        String nextUrl = shouldOverrideUrlLoadingRequest.url;
        if (nextUrl.startsWith("http:") || nextUrl.startsWith("https:")) {
          webView.loadUrl(url: nextUrl);
          return;
        } else {
          launch(nextUrl);
        }
        return null;
      },
    );
  }

  Widget _getIndicatorBar() {
    return progress < 1.0
        ? LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white70,
            valueColor: animation)
        : Container();
  }

  void showMenuClick() {
    double offsetTop =
        appBar.preferredSize.height + getStatueBarHeight(context);
    double offsetLeft = getScreenSize(context).width;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(offsetLeft, offsetTop, 0, 0),
      items: <PopupMenuEntry>[
        PopupMenuItem(
          child: Text("刷新"),
          value: 1,
        ),
        PopupMenuItem(
          child: Text("浏览器打开"),
          value: 2,
        ),
        PopupMenuItem(
          child: Text("复制链接"),
          value: 3,
        ),
        PopupMenuItem(
          child: Text("收藏"),
          value: 4,
        ),
        PopupMenuItem(
          child: Text("分享"),
          value: 5,
        ),
      ],
    ).then((value) {
      switch (value) {
        case 1:
          webView.reload();
          break;
        case 2:
          launch(url);
          break;
        case 3:
          Clipboard.setData(ClipboardData(text: url));
          AppToastUtils.showToast("链接已复制");
          break;
        case 4:
          // TODO
          break;
        case 5:
          // TODO
          break;
      }
    });
  }
}

class ColorsAnimation extends Animation<Color> {
  double progress;

  ColorsAnimation({this.progress});

  updateValues(double progress) {
    this.progress = progress;
  }

  @override
  void addListener(listener) {}

  @override
  void addStatusListener(listener) {}

  @override
  void removeListener(listener) {}

  @override
  void removeStatusListener(listener) {}

  @override
  AnimationStatus get status {
    return progress == 1 ? AnimationStatus.completed : AnimationStatus.forward;
  }

  @override
  Color get value =>
      Color(((Colors.white24.value - Colors.white60.value) * progress +
              Colors.white60.value)
          .toInt());
}
