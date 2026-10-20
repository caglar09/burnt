package expo.modules.burnt.overlay

import expo.modules.kotlin.records.Field
import expo.modules.kotlin.records.Record
import expo.modules.kotlin.types.Enumerable

enum class DialogIcon(val raw: String) : Enumerable {
  none("none"), info("info"), success("success"), warning("warning"), error("error")
}
enum class DialogPolicy(val raw: String) : Enumerable {
  enqueue("enqueue"), replace("replace"), reject("reject")
}
enum class DialogActionStyle(val raw: String) : Enumerable {
  `default`("default"), cancel("cancel"), destructive("destructive")
}
enum class DialogFieldType(val raw: String) : Enumerable {
  text("text"), textarea("textarea")
}

class DialogAction : Record {
  @Field var id: String = ""
  @Field var title: String = ""
  @Field var style: DialogActionStyle = DialogActionStyle.default
}
class DialogField : Record {
  @Field var id: String = ""
  @Field var type: DialogFieldType = DialogFieldType.text
  @Field var placeholder: String? = null
  @Field var value: String = ""
  @Field var required: Boolean = false
  @Field var maxLength: Int? = null
}
class DialogOptions : Record {
  @Field var title: String = ""
  @Field var message: String? = null
  @Field var icon: DialogIcon = DialogIcon.none
  @Field var fields: List<DialogField> = emptyList()
  @Field var actions: List<DialogAction> = emptyList()
  @Field var dismissOnBackdrop: Boolean = false
  @Field var dismissOnBack: Boolean = true
  @Field var queuePolicy: DialogPolicy = DialogPolicy.enqueue
}
