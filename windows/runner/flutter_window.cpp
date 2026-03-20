#include "flutter_window.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <optional>

#include "flutter/generated_plugin_registrant.h"

static const wchar_t* kRunKey =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\Run";
static const wchar_t* kAppName = L"BusyLightBuddy";
 
static bool IsAutostartEnabled() {
  HKEY key;
  if (RegOpenKeyEx(HKEY_CURRENT_USER, kRunKey, 0, KEY_READ, &key) != ERROR_SUCCESS)
    return false;
  DWORD type, size = 0;
  bool exists = RegQueryValueEx(key, kAppName, nullptr, &type, nullptr, &size) == ERROR_SUCCESS;
  RegCloseKey(key);
  return exists;
}
 
static void SetAutostartEnabled(bool enabled) {
  HKEY key;
  if (RegOpenKeyEx(HKEY_CURRENT_USER, kRunKey, 0, KEY_WRITE, &key) != ERROR_SUCCESS)
    return;
  if (enabled) {
    wchar_t path[MAX_PATH];
    GetModuleFileName(nullptr, path, MAX_PATH);
    RegSetValueEx(key, kAppName, 0, REG_SZ,
                  reinterpret_cast<const BYTE*>(path),
                  static_cast<DWORD>((wcslen(path) + 1) * sizeof(wchar_t)));
  } else {
    RegDeleteValue(key, kAppName);
  }
  RegCloseKey(key);
}
 
void FlutterWindow::SetupAutostart() {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      "com.igox.busylight_buddy/autostart",
      &flutter::StandardMethodCodec::GetInstance());
 
  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "isEnabled") {
          result->Success(flutter::EncodableValue(IsAutostartEnabled()));
        } else if (call.method_name() == "setEnabled") {
          auto args = std::get<flutter::EncodableMap>(*call.arguments());
          bool enabled = std::get<bool>(args[flutter::EncodableValue("enabled")]);
          SetAutostartEnabled(enabled);
          result->Success();
        } else {
          result->NotImplemented();
        }
      });
 
  autostart_channel_ = std::move(channel);
}

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetupAutostart();  // ← called here after RegisterPlugins
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}