import SwiftUI

public struct GroupedPicker<T>: NSViewRepresentable where T: GroupedPickerItem {
    
    // MARK: Bindings
    
    /// 選択されている要素
    @Binding var selection: T?
    
    // MARK: Properties
    
    /// ピッカーに表示する要素
    private var items: [T]
    
    /// グループが選択できるかどうか
    private var groupSelectable = false
    
    /// フォルダーアイコン
    private var folderImage = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
    
    /// 選択肢アイコン
    private var itemImage = NSImage(systemSymbolName: "doc", accessibilityDescription: nil)
    
    private var listedItems = [ListedItem]()
    
    // MARK: Initializers
    
    /// イニシャライザー
    /// - Parameters:
    ///   - items: ピッカーに表示する要素
    ///   - selection: 選択する要素
    ///   - deselectItems: 選択できない要素
    public init(items: [T], selection: Binding<T?>) {
        self.items = items
        _selection = selection
        listedItems = listedItems(nodes: items)
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
            guard let menuItem = sender as? NSMenuItem,
                  let menu = menuItem.menu else {
                return
            }
            let selectedIndex = menu.index(of: menuItem)
            groupedPicker.selection = groupedPicker.listedItems[selectedIndex].node
        }
    }
    
    // MARK: Private Struct
    
    /// グループ構造を、一列に並べた時の要素
    private struct ListedItem {
        let title: String
        let node: T
        let selectable: Bool
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
                $0.append(ListedItem(title: $1.title, node: $1, selectable: $1.selectable, indentLevel: indentLevel))
                $0 += listedItems(nodes: children, indentLevel: indentLevel + 1)
            } else {
                $0.append(ListedItem(title: $1.title, node: $1, selectable: $1.selectable, indentLevel: indentLevel))
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
        popUpButton.menu?.items = listedItems.map { item in
            let menuItem = NSMenuItem(
                title: item.title,
                action: #selector(context.coordinator.selected),
                keyEquivalent: ""
            )
            menuItem.indentationLevel = item.indentLevel
            menuItem.target = context.coordinator
            menuItem.isEnabled = (!item.isGroup && item.selectable) || (item.isGroup && groupSelectable)
            menuItem.image = item.isGroup ? folderImage : itemImage
            return menuItem
        }
        if let index = listedItems.firstIndex(where: { $0.node == selection && ((!$0.isGroup && $0.selectable) || ($0.isGroup && groupSelectable)) }) {
            popUpButton.selectItem(at: index)
        } else if let index = popUpButton.menu?.items.firstIndex(where: { $0.isEnabled }) {
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
    
    /// グループを選択できるようにする
    /// - Parameter selectable: 選択可能かどうかをあらわすBool
    /// - Returns: GroupedPicker
    public func groupSelectable(_ selectable: Bool) -> GroupedPicker {
        var view = self
        view.groupSelectable = selectable
        return view
    }
}

/// GroupedPickerの要素となるプロトコル
public protocol GroupedPickerItem: Identifiable, Equatable {
    /// 要素として表示する名称
    var title: String { get }
    
    /// 子要素の配列
    /// nilの場合、要素自身が末端となる。nilでない場合は、要素自身はグループになる。
    var children: [Self]? { get }
    
    /// 要素が選択可能かどうか
    var selectable: Bool { get }
}

// MARK: - Previews

struct City: GroupedPickerItem {
    var title: String
    
    var children: [City]?
    
    var selectable: Bool = true
    
    let id = UUID()
}

struct GroupedPicker_Previews: PreviewProvider {
    
    static let cities: [City] = [
        City(
            title: "Asia",
            children: [
                City(title: "Japan", children: [
                    City(title: "Tokyo", children: nil, selectable: true),
                    City(title: "Osaka", children: nil)
                ]),
                City(title: "China", children: nil)
            ]
        ),
        City(
            title: "Europ",
            children: [
                City(title: "Fra", children: nil),
                City(title: "Ita", children: nil),
                City(title: "Dot", children: nil)
            ]
        )
    ]
    
    static var previews: some View {
        HStack {
            GroupedPicker(items: cities, selection: .constant(cities[0].children?[0]))
                .menuImage(
                    folderImage: NSImage(systemSymbolName: "circle.circle", accessibilityDescription: nil),
                    itemImage: NSImage(systemSymbolName: "circle", accessibilityDescription: nil))
                .groupSelectable(true)
        }
    }
}
