import SwiftUI

public struct GroupedPicker<T>: NSViewRepresentable where T: GroupedPickerItem {
    
    // MARK: Bindings
    
    /// ピッカーに表示するアイテム
    @Binding var items: [T]
    
    /// 選択されているアイテム
    @Binding var selected: T?
    
    /// 選択できないアイテム
    @Binding var deselectItems: [T]?
    
    // MARK: Properties
    
    // MARK: Initializers
    
    /// イニシャライザー
    /// - Parameters:
    ///   - items: ピッカーに表示するアイテム
    ///   - selected: 選択するアイテム
    ///   - deselectItems: 選択できないアイテム
    init(items: Binding<[T]>, selected: Binding<T?>, deselectItems: Binding<[T]?> = .constant(nil)) {
        _items = items
        _selected = selected
        _deselectItems = deselectItems
    }
    
    // MARK: Public Functions
    
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
    
    public func makeCoordinator() -> GroupedPickerCoordinator {
        GroupedPickerCoordinator(self)
    }
    
    // MARK: Public Classes

    public class GroupedPickerCoordinator: NSObject {
        private var groupedPicker: GroupedPicker

        init(_ groupedPicker: GroupedPicker) {
            self.groupedPicker = groupedPicker
        }

        @objc
        func selected(sender: Any) {
            guard let popUpButton = sender as? NSPopUpButton else {
                return
            }
            let selectedIndex = popUpButton.indexOfSelectedItem
            groupedPicker.selected = groupedPicker.items[selectedIndex]
        }
    }
    
    // MARK: Private Struct
    
    /// グループ構造を、一列に並べた時の要素
    private struct ListedItem {
        let name: String
        let node: T
        var isGroup: Bool { node.children != nil }
    }

    // MARK: Private Functions
    
    /// グループ構造を一列に並べる
    /// - Parameters:
    ///   - nodes: グループ
    ///   - prefix: 段下げ文字
    /// - Returns: 一列に並べ替えた配列
    private func listedItems(nodes: [T], prefix: String = "") -> [ListedItem] {
        nodes.reduce(into: [ListedItem]()) {
            if let children = $1.children {
                $0.append(ListedItem(name: $1.name, node: $1))
                $0 += listedItems(nodes: children, prefix: prefix + " ")
            } else {
                $0.append(ListedItem(name: prefix + $1.name, node: $1))
            }
        }
    }
    
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
            menuItem.target = context.coordinator
            menuItem.isEnabled = {
                if $0.isGroup {
                    return false
                }
                guard let deselectItems = deselectItems else {
                    return true
                }
                return !deselectItems.contains($0.node)
            }(item)
            menuItem.image = item.isGroup
                ? NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
                : nil
            return menuItem
        }
        if let index = listedItems.firstIndex(where: { $0.node == selected }) {
            popUpButton.selectItem(at: index)
        } else if let index = listedItems.firstIndex(where: { !$0.isGroup }) {
            popUpButton.selectItem(at: index)
        }
    }
    
}

/// GroupedPickerを使うためのプロトコル
public protocol GroupedPickerItem: Identifiable, Equatable {
    var name: String { get }
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
        City(name: "Asia",
             children: [
                City(name: "Japan", children: nil),
                City(name: "China", children: nil)
             ]
            ),
        City(name: "Europ",
             children: [
                City(name: "Fra", children: nil),
                City(name: "Ita", children: nil)
             ]
            )
    ]
    
    static var previews: some View {
        GroupedPicker(items: .constant(cities), selected: .constant(nil))
    }
}
