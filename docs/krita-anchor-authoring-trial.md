# Krita Anchor 手動校正試驗

這是一個小型手動試驗，用來驗證 Krita 能否作為免費的預覽／校正工具，
在投入更完整的寵物動畫製作流程前，先確認這條路是否可行。

## 適用範圍
- 寵物／狀態：`ghost` / `stay`
- 圖片序列：`assets/pet/ghost/ghost_stay/ghost_stay-01.png` 到
  `assets/pet/ghost/ghost_stay/ghost_stay-13.png`
- 第一輪目標：先把整個 idle loop 的 `head` socket 校準好。如果整個流程
  手感不錯，再繼續補 `body` 與 `back`。

## 目標
使用 Krita 作為外部預覽介面，逐 frame 進行手動 anchor/socket 校正，然後把
最後選定的點位寫入一份小型 JSON 檔，供 repo 後續轉換成正式資料格式。

## 試驗步驟
1. 啟動 Krita。
2. 用 `assets/pet/ghost/ghost_stay/` 這組 PNG sequence 建立或匯入動畫。
3. 保持原始畫布尺寸為 `450x450`，這樣記錄下來的座標才會與原始素材完全一致。
4. 如有需要，可開啟動畫播放與 onion skin，方便觀察整段動作。
5. 在 ghost 圖層上方新增簡單的 marker 圖層：
   - `head_marker`：紅色
   - `body_marker`：綠色
   - `back_marker`：藍色
6. 逐 frame 拖動 marker，直到它在視覺上穩定跟住寵物移動。

## 需要記錄的資料
請記錄「原始像素座標」，不要先轉成 normalized 值。這個試驗階段只需要記錄
每一幀 marker 中心點的位置。

請使用以下資料結構：

```json
{
  "pet_id": "ghost",
  "state": "idle",
  "canvas": { "width": 450, "height": 450 },
  "frames": [
    {
      "frame": 1,
      "file": "ghost_stay-01.png",
      "sockets": {
        "head": { "x": 225, "y": 104 },
        "body": { "x": 225, "y": 252 },
        "back": { "x": 302, "y": 194 }
      }
    }
  ]
}
```

範本檔案：
- `docs/templates/ghost_anchor_trial.template.json`

## 建議校正規則
- 整個 loop 內，marker 要盡量固定追同一個視覺基準點。
- 以穩定為優先，不要過度追求每一幀極細微的抖動。如果相鄰兩幀肉眼幾乎無差異，
  可以直接沿用同一個點位。
- 對帽子／頭部裝備來說，建議使用裝備與頭部接觸區域的底部中心點。
- 對 `body` / `back` slot 來說，應以裝備實際貼附區域的視覺中心為準，而不是角色
  輪廓最外側。

## 成功標準
只要以下條件都成立，就代表這個試驗值得繼續：
- 在 Krita 內來回 scrub PNG sequence 的手感夠快。
- 拖動與更新 marker 的過程不會明顯卡工具。
- 記錄出來的點位足夠一致，能生成可信的 overlay motion track。
- 用 JSON 做資料交接在 10 到 30 幀的規模下仍然實際，不只適用於 3 到 5 幀。

## 如果試驗成功
repo 下一步可以做：
1. 加一個 converter，讀取你記錄完成的 JSON。
2. 依照原始畫布尺寸，把像素座標轉成 normalized 座標。
3. 生成 Flutter 端可用的 `PetSocketConfig` 基礎／override 數值，以及可選的
   `PetMotionTrack` frame data。

目前 repo 內已提供第一版 converter：
- `tool/convert_anchor_trial.py`

用法示例：

```sh
python3 tool/convert_anchor_trial.py docs/templates/ghost_anchor_trial.template.json --slot head
```

## 如果試驗不成功
下一輪可測試的替代方案：
- `LibreSprite`：如果你想要一個更偏 sprite / animation editor 的工具。
- 自製一個極小型 web preview 工具：直接播放 PNG sequence，並支援在瀏覽器內拖動
  socket marker。
