# GroupedPicker

macOSにおいて、NSPopupButtonをSwiftUIで利用するためのView.

## 製作理由

SwiftUIの標準のPickerでは、階層的なメニューを作りにくく、また、選択できないメニューを作ることも困難である。
macOSであれば、NSPopupButtonを使うことで、簡単に実装することができる。

## 概略

NSPopupButtonに表示させたいメニュー項目をGroupedPickerItemプロトコルに適合した配列に入れることで、階層的なポップアップボタンを作成することができる。

<img width="319" alt="スクリーンショット 2022-04-29 17 13 53" src="https://user-images.githubusercontent.com/34973981/165907980-5c708193-787c-41a7-b60a-7508233284b2.png">

```swift

  @State var selection: City = cities[0]
  
  struct City: GroupedPickerItem {
    var title: String
    var children: [City]?
    var selectable: Bool = true
    let id = UUID()
  }
  
  static let cities: [City] = [
    City(title: "北海道"),
    City(title: "東北",
         children: [
           City(title: "青森"),
(中略)
         ]
    )
  ]
    
  static var previews: some View {
    HStack {
      GroupedPicker(items: cities, selection: $selection)
    }
  }
  ```
