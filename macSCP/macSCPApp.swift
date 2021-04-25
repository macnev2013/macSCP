//
//  macSCPApp.swift
//  macSCP
//
//  Created by Nevil Macwan on 24/04/21.
//

import SwiftUI
import Combine
import CoreData

@main
struct macSCPApp: App {
    let persistanceController = PersistanceController.shared
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistanceController.container.viewContext)
        }
        .onChange(of: scenePhase, perform: { (newScenePhase) in
            switch newScenePhase {
            case .background:
                print("Scene is in backgroup")
                persistanceController.save()
            case .inactive:
                print("Scene is inactive")
            case .active:
                print("Scene is active")
            @unknown default:
                print("App needs an updated")
            }
        })
        .commands {
            SidebarCommands()
        }
    }
}
