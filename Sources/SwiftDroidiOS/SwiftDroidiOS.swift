// Curated aliases instead of `@_exported import SwiftUI`: anything the core
// doesn't implement (List, NavigationStack…) fails to compile here too.

#if canImport(SwiftUI)
import SwiftUI
import Combine

public typealias View = SwiftUI.View
public typealias ViewBuilder = SwiftUI.ViewBuilder

public typealias Text = SwiftUI.Text
public typealias Button = SwiftUI.Button
public typealias EmptyView = SwiftUI.EmptyView
public typealias Spacer = SwiftUI.Spacer
public typealias VStack = SwiftUI.VStack
public typealias HStack = SwiftUI.HStack
public typealias ZStack = SwiftUI.ZStack
public typealias Group = SwiftUI.Group
public typealias Divider = SwiftUI.Divider
public typealias TupleView = SwiftUI.TupleView
public typealias ForEach = SwiftUI.ForEach
public typealias ScrollView = SwiftUI.ScrollView
public typealias LazyVStack = SwiftUI.LazyVStack
public typealias List = SwiftUI.List
public typealias Section = SwiftUI.Section

public typealias Alignment = SwiftUI.Alignment
public typealias HorizontalAlignment = SwiftUI.HorizontalAlignment
public typealias VerticalAlignment = SwiftUI.VerticalAlignment
public typealias EdgeInsets = SwiftUI.EdgeInsets
public typealias Edge = SwiftUI.Edge
public typealias Axis = SwiftUI.Axis

public typealias Font = SwiftUI.Font
public typealias Color = SwiftUI.Color

public typealias State = SwiftUI.State
public typealias Binding = SwiftUI.Binding
public typealias ObservedObject = SwiftUI.ObservedObject
public typealias ObservableObject = Combine.ObservableObject
public typealias Published = Combine.Published
#endif
