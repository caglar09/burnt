import Foundation
import ExpoModulesCore

enum NativeDialogIcon: String, Enumerable {
  case none, info, success, warning, error
}
enum NativeDialogPolicy: String, Enumerable {
  case enqueue, replace, reject
}
enum NativeDialogActionStyle: String, Enumerable {
  case `default`, cancel, destructive
}
enum NativeDialogFieldType: String, Enumerable {
  case text, textarea
}
struct NativeDialogAction: Record {
  @Field var id: String = ""
  @Field var title: String = ""
  @Field var style: NativeDialogActionStyle = .default
}
struct NativeDialogField: Record {
  @Field var id: String = ""
  @Field var type: NativeDialogFieldType = .text
  @Field var placeholder: String?
  @Field var value: String = ""
  @Field var required: Bool = false
  @Field var maxLength: Int?
}
struct NativeDialogOptions: Record {
  @Field var title: String = ""
  @Field var message: String?
  @Field var icon: NativeDialogIcon = .none
  @Field var fields: [NativeDialogField] = []
  @Field var actions: [NativeDialogAction] = []
  @Field var dismissOnBackdrop: Bool = false
  @Field var dismissOnBack: Bool = true
  @Field var queuePolicy: NativeDialogPolicy = .enqueue
}
