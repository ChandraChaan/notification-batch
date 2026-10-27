/// What Android currently allows, and where the batch stands.
class BatchStatus {
  const BatchStatus({
    required this.listenerEnabled,
    this.listenerConnected = false,
    this.notificationsAllowed = true,
    this.contactsAllowed = false,
    this.exactAlarmsAllowed = true,
    this.nextDeliveryAt,
    this.heldCount = 0,
    this.lastDeliveryAt,
  });

  /// The user granted notification access in system settings.
  final bool listenerEnabled;

  /// Android has actually bound the listener. Usually follows [listenerEnabled] within a second.
  final bool listenerConnected;

  /// The app may post the batch summary (Android 13 asks for this separately).
  final bool notificationsAllowed;

  final bool contactsAllowed;

  /// Without exact alarms a delivery can be a few minutes late.
  final bool exactAlarmsAllowed;

  /// UTC.
  final DateTime? nextDeliveryAt;
  final int heldCount;

  /// UTC.
  final DateTime? lastDeliveryAt;

  @override
  bool operator ==(Object other) =>
      other is BatchStatus &&
      other.listenerEnabled == listenerEnabled &&
      other.listenerConnected == listenerConnected &&
      other.notificationsAllowed == notificationsAllowed &&
      other.contactsAllowed == contactsAllowed &&
      other.exactAlarmsAllowed == exactAlarmsAllowed &&
      other.nextDeliveryAt == nextDeliveryAt &&
      other.heldCount == heldCount &&
      other.lastDeliveryAt == lastDeliveryAt;

  @override
  int get hashCode => Object.hash(
    listenerEnabled,
    listenerConnected,
    notificationsAllowed,
    contactsAllowed,
    exactAlarmsAllowed,
    nextDeliveryAt,
    heldCount,
    lastDeliveryAt,
  );
}
