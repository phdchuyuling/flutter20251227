# Reversi (Othello) - Flutter Web

簡單的 Reversi（黑白棋）遊戲，使用 Flutter Web 開發。這個版本難度很低，適合打發時間：

- 人類玩家先手（黑），電腦為白色，AI 使用簡單的貪婪策略（翻最多子，平手時隨機）。
- 可在本地以瀏覽器執行。

快速啟動（Windows PowerShell）：

```powershell
# 確認已安裝 Flutter 並可使用 web
flutter channel stable
flutter upgrade
flutter config --enable-web

# 在專案根目錄
flutter pub get
flutter run -d chrome
```

若要建立 release build：

```powershell
flutter build web
```

檔案重點：
- `lib/main.dart` - UI 與整體流程
- `lib/game.dart` - 棋盤與遊戲規則邏輯
- `lib/ai.dart` - 簡單 AI 策略
"# Project_2025-1210" 
