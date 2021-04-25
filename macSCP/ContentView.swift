//
//  ContentView.swift
//  macSCP
//
//  Created by Nevil Macwan on 24/04/21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            SidebarView()
            Text("No Connection Added Yet")
            Text("No Connection Selected")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
