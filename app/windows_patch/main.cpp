#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");
  std::vector<std::string> command_line_arguments = GetCommandLineArguments();
  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  // Окно «как телефон»: узкое, во всю высоту рабочей области, по центру экрана
  RECT wa;
  ::SystemParametersInfo(SPI_GETWORKAREA, 0, &wa, 0);
  double scale = ::GetDpiForSystem() / 96.0;
  int workW = (int)((wa.right - wa.left) / scale);
  int workH = (int)((wa.bottom - wa.top) / scale);
  int winW = 540;
  int winH = workH - 8;
  if (winH < 600) winH = 600;
  int x = (int)(wa.left / scale) + (workW - winW) / 2;
  int y = (int)(wa.top / scale) + 4;

  FlutterWindow window(project);
  Win32Window::Point origin(x, y);
  Win32Window::Size size(winW, winH);
  if (!window.Create(L"Fiber Finder", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
