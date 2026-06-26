//
//  NetfuelWidgetBundle.swift
//  NetfuelWidget
//
//  Created by Ricky Elder on 6/25/26.
//

import WidgetKit
import SwiftUI

@main
struct NetfuelWidgetBundle: WidgetBundle {
    var body: some Widget {
        NetfuelWidget()
        NetfuelWidgetControl()
    }
}
