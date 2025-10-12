import 'dart:io';

void openFolderInExplorer(String path) {
  if (Platform.isWindows) {
    Process.run('explorer', [path]);
  } else if (Platform.isMacOS) {
    Process.run('open', [path]);
  } else if (Platform.isLinux) {
    Process.run('xdg-open', [path]);
  } else {
    throw UnsupportedError('해당 플랫폼은 지원예정입니다.');
  }
}