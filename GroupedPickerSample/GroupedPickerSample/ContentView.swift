//
//  ContentView.swift
//  GroupedPickerSample
//
//  Created by 窪田直樹 on 2022/04/24.
//

import SwiftUI
import GroupedPicker

struct City: GroupedPickerItem {
    var selectable: Bool = true
    var title: String
    var children: [City]?
    let id = UUID()
}

struct ContentView: View {
    static let cities: [City] = [
        City(title: "北海道"),
        City(
            title: "東北",
            children: [
                City(title: "青森"),
                City(title: "岩手"),
                City(title: "宮城"),
                City(title: "秋田"),
                City(title: "山形"),
                City(title: "福島")
            ]
        ),
        City(
            title: "関東",
            children: [
                City(title: "茨城"),
                City(title: "栃木"),
                City(title: "群馬"),
                City(title: "埼玉"),
                City(title: "千葉"),
                City(title: "東京", children: [
                    City(title: "区内"),
                    City(title: "区外")
                ]),
                City(title: "神奈川県")
            ]
        )
    ]
    
    @State var selection = cities[0]
    
    @State var canSelectGroup = false
    
    @State var usesCircle = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Selection: \(selection.title)")
                    .padding()
                if usesCircle {
                GroupedPicker(items: ContentView.cities, selection: $selection)
                    .groupSelectable(canSelectGroup)
                    .menuImage(folderImage: NSImage(systemSymbolName: "circle.circle", accessibilityDescription: nil), itemImage: NSImage(systemSymbolName: "circle", accessibilityDescription: nil))
                    .padding()
                } else {
                    GroupedPicker(items: ContentView.cities, selection: $selection)
                        .groupSelectable(canSelectGroup)
                        .padding()

                }
            }
            HStack {
                Toggle("Groups can select", isOn: $canSelectGroup)
                    .padding()
                Toggle("Change Icon", isOn: $usesCircle)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
