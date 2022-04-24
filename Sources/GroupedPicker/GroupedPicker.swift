import SwiftUI

public struct GroupedPicker<T>: NSViewRepresentable where T: GroupedPickerItem {
    
    // MARK: Bindings
    
    /// 選択されている要素
    @Binding var selection: T?
    
    // MARK: Properties
    
    /// ピッカーに表示する要素
    private var items: [T]
    
    /// 選択できない要素
    /// 表示はするが、選択できない要素。例えば、すでに選択されている要素を選択できないようにする時などに使用する
    private var deselectItems: [T] = []
    
    /// フォルダーアイコン
    private var folderImage = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
    
    /// 選択肢アイコン
    private var itemImage = NSImage(systemSymbolName: "doc", accessibilityDescription: nil)
    
    // MARK: Initializers
    
    /// イニシャライザー
    /// - Parameters:
    ///   - items: ピッカーに表示する要素
    ///   - selection: 選択する要素
    ///   - deselectItems: 選択できない要素
    public init(items: [T], selection: Binding<T?>) {
        self.items = items
        _selection = selection
    }
    
    // MARK: Public NSViewRepresentable Functions
    
    /// NSViewを作成する
    /// - Parameter context: GroupedPickerCoordinator
    /// - Returns: NSView
    public func makeNSView(context: Context) -> some NSView {
        let popUpButton = NSPopUpButton()
        setPopUpButton(popUpButton, context: context)
        return popUpButton
    }
    
    /// NSViewを更新する
    /// - Parameters:
    ///   - nsView: NSView
    ///   - context: GroupedPickerCoordinator
    public func updateNSView(_ nsView: NSViewType, context: Context) {
        if let button = nsView as? NSPopUpButton {
            setPopUpButton(button, context: context)
        }
    }
    
    /// コーディネーターを作成する
    /// - Returns: コーディネーター
    public func makeCoordinator() -> GroupedPickerCoordinator {
        GroupedPickerCoordinator(self)
    }
    
    // MARK: Public Functions
    
    
    // MARK: Public Classes
    
    /// コーディネーター
    public class GroupedPickerCoordinator: NSObject {
        /// コーディネーターが接続されたGroupedPicker
        private var groupedPicker: GroupedPicker
        
        /// イニシャライザー
        /// - Parameter groupedPicker: コーディネーターを接続するGroupedPicker
        init(_ groupedPicker: GroupedPicker) {
            self.groupedPicker = groupedPicker
        }
        
        @objc
        /// Pickerが選択されたときの処理
        /// - Parameter sender: 選択されたPicker
        func selected(sender: Any) {
            guard let popUpButton = sender as? NSPopUpButton else {
                return
            }
            let selectedIndex = popUpButton.indexOfSelectedItem
            groupedPicker.selection = groupedPicker.items[selectedIndex]
        }
    }
    
    // MARK: Private Struct
    
    /// グループ構造を、一列に並べた時の要素
    private struct ListedItem {
        let name: String
        let node: T
        let indentLevel: Int
        var isGroup: Bool { node.children != nil }
    }
    
    // MARK: Private Functions
    
    /// グループ構造を一列に並べる
    /// - Parameters:
    ///   - nodes: グループ
    ///   - indentLevel: 字下げ量
    /// - Returns: 一列に並べ替えた配列
    private func listedItems(nodes: [T], indentLevel: Int = 0) -> [ListedItem] {
        nodes.reduce(into: [ListedItem]()) {
            if let children = $1.children {
                $0.append(ListedItem(name: $1.name, node: $1, indentLevel: indentLevel))
                $0 += listedItems(nodes: children, indentLevel: indentLevel + 1)
            } else {
                $0.append(ListedItem(name: $1.name, node: $1, indentLevel: indentLevel))
            }
        }
    }
    
    /// ポップアップボタンの中身を作成する
    /// - Parameters:
    ///   - popUpButton: 中身を作成するポップアップボタン
    ///   - context: ポップアップが選択されたときに呼び出すコンテクスト
    private func setPopUpButton(_ popUpButton: NSPopUpButton, context: Context) {
        popUpButton.removeAllItems()
        popUpButton.autoenablesItems = false
        let listedItems = listedItems(nodes: items)
        popUpButton.menu?.items = listedItems.map { item in
            let menuItem = NSMenuItem(
                title: item.name,
                action: #selector(context.coordinator.selected),
                keyEquivalent: ""
            )
            menuItem.indentationLevel = item.indentLevel
            menuItem.target = context.coordinator
            menuItem.isEnabled = {
                if $0.isGroup {
                    return false
                }
                return !deselectItems.contains($0.node)
            }(item)
            menuItem.image = item.isGroup ? folderImage : itemImage
            return menuItem
        }
        if let index = listedItems.firstIndex(where: { $0.node == selection }) {
            popUpButton.selectItem(at: index)
        } else if let index = listedItems.firstIndex(where: { !$0.isGroup }) {
            popUpButton.selectItem(at: index)
        }
    }
    
}

// MARK: Modifiers

extension GroupedPicker {
    /// フォルダアイコン、要素アイコンを変更する
    /// - Parameters:
    ///   - folderImage: フォルダーにつけるアイコン
    ///   - itemImage: 要素につけるアイコン
    /// - Returns: GroupedPicker
    public func menuImage(folderImage: NSImage? = nil, itemImage: NSImage? = nil) -> GroupedPicker {
        var view = self
        view.folderImage = folderImage
        view.itemImage = itemImage
        return view
    }
    
    /// 選択できない要素を設定する
    /// - Parameter items: 設定できない要素の配列
    /// - Returns: GroupedPicker
    public func deselectItems(_ items: [T]) -> GroupedPicker {
        var view = self
        view.deselectItems = items
        print(items)
        return view
    }
}

/// GroupedPickerを使うためのプロトコル
public protocol GroupedPickerItem: Identifiable, Equatable {
    /// ピッカーに表示する名称
    var name: String { get }
    
    /// グループの子要素
    var children: [Self]? { get }
}

// MARK: - Previews

struct City: GroupedPickerItem {
    var name: String
    var children: [City]?
    let id = UUID()
}

struct GroupedPicker_Previews: PreviewProvider {
    
    static let cities: [City] = [
        City(
            name: "Asia",
            children: [
                City(name: "Japan", children: [
                    City(name: "Tokyo", children: nil),
                    City(name: "Osaka", children: nil)
                ]),
                City(name: "China", children: nil)
            ]
        ),
        City(
            name: "Europ",
            children: [
                City(name: "Fra", children: nil),
                City(name: "Ita", children: nil),
                City(name: "Dot", children: nil)
            ]
        )
    ]
    
    enum Flavor: String, CaseIterable, Identifiable {
        case chocolate, vanilla, strawberry
        var id: Self { self }
    }
    
    static var previews: some View {
        HStack {
            GroupedPicker(items: cities, selection: .constant(cities[1].children?[1]))
                .deselectItems([cities[1].children![0], cities[1].children![2]])
                .menuImage(
                    folderImage: NSImage(systemSymbolName: "circle.circle", accessibilityDescription: nil),
                    itemImage: NSImage(systemSymbolName: "circle", accessibilityDescription: nil))
            List(cities, children: \.children) { item in
                Text(item.name)
            }
            List {
                Picker("Fravor", selection: .constant(Flavor.chocolate)) {
                    Text("Chocolate").tag(Flavor.chocolate)
                    Text("Vanilla").tag(Flavor.vanilla)
                }
            }
        }
    }
}
