using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;

namespace WC3ItemManager.Models
{
    /// <summary>
    /// Presents an existing model to PropertyGrid while applying per-property source-edit permissions.
    /// </summary>
    public sealed class SelectivePropertyModel : ICustomTypeDescriptor
    {
        private readonly object _target;
        private readonly IReadOnlyDictionary<string, SourceFieldAccess> _access;
        private readonly string _defaultReadOnlyReason;

        public SelectivePropertyModel(object target, IReadOnlyDictionary<string, SourceFieldAccess> access,
            string defaultReadOnlyReason)
        {
            _target = target ?? throw new ArgumentNullException(nameof(target));
            _access = access ?? new Dictionary<string, SourceFieldAccess>();
            _defaultReadOnlyReason = defaultReadOnlyReason ?? "This value is only editable in the JASS source file.";
        }

        public AttributeCollection GetAttributes() => TypeDescriptor.GetAttributes(_target, true);
        public string GetClassName() => TypeDescriptor.GetClassName(_target, true);
        public string GetComponentName() => TypeDescriptor.GetComponentName(_target, true);
        public TypeConverter GetConverter() => TypeDescriptor.GetConverter(_target, true);
        public EventDescriptor GetDefaultEvent() => TypeDescriptor.GetDefaultEvent(_target, true);
        public PropertyDescriptor GetDefaultProperty() => TypeDescriptor.GetDefaultProperty(_target, true);
        public object GetEditor(Type editorBaseType) => TypeDescriptor.GetEditor(_target, editorBaseType, true);
        public EventDescriptorCollection GetEvents(Attribute[] attributes) => TypeDescriptor.GetEvents(_target, attributes, true);
        public EventDescriptorCollection GetEvents() => TypeDescriptor.GetEvents(_target, true);

        public PropertyDescriptorCollection GetProperties(Attribute[] attributes)
        {
            var properties = TypeDescriptor.GetProperties(_target, attributes, true)
                .Cast<PropertyDescriptor>()
                .Select(property => new SelectivePropertyDescriptor(
                    property,
                    _target,
                    _access.TryGetValue(property.Name, out SourceFieldAccess field) ? field : null,
                    _defaultReadOnlyReason))
                .ToArray();
            return new PropertyDescriptorCollection(properties, true);
        }

        public PropertyDescriptorCollection GetProperties() => GetProperties(Array.Empty<Attribute>());
        public object GetPropertyOwner(PropertyDescriptor propertyDescriptor) => _target;

        private sealed class SelectivePropertyDescriptor : PropertyDescriptor
        {
            private readonly PropertyDescriptor _inner;
            private readonly object _target;
            private readonly SourceFieldAccess _access;
            private readonly string _defaultReadOnlyReason;

            public SelectivePropertyDescriptor(PropertyDescriptor inner, object target, SourceFieldAccess access,
                string defaultReadOnlyReason) : base(inner)
            {
                _inner = inner;
                _target = target;
                _access = access;
                _defaultReadOnlyReason = defaultReadOnlyReason;
            }

            public override bool IsReadOnly => _inner.IsReadOnly || _access?.Editable != true;
            public override string Description
            {
                get
                {
                    if (_access?.Editable == true)
                    {
                        return string.IsNullOrWhiteSpace(_inner.Description)
                            ? "Safely mapped to a recognized JASS literal. Saving will show a source patch preview."
                            : _inner.Description + " Safely mapped to a recognized JASS literal; saving shows a patch preview.";
                    }
                    string reason = _access?.Reason;
                    if (string.IsNullOrWhiteSpace(reason)) reason = _defaultReadOnlyReason;
                    return "Contains custom or unmappable source logic. " + reason;
                }
            }

            public override Type ComponentType => _inner.ComponentType;
            public override Type PropertyType => _inner.PropertyType;
            public override bool CanResetValue(object component) => !IsReadOnly && _inner.CanResetValue(_target);
            public override object GetValue(object component) => _inner.GetValue(_target);
            public override void ResetValue(object component) => _inner.ResetValue(_target);
            public override void SetValue(object component, object value)
            {
                if (IsReadOnly) return;
                _inner.SetValue(_target, value);
                OnValueChanged(component, EventArgs.Empty);
            }
            public override bool ShouldSerializeValue(object component) => _inner.ShouldSerializeValue(_target);
        }
    }

    public sealed class SourceFieldAccess
    {
        public string PropertyName { get; set; } = "";
        public bool Editable { get; set; }
        public string Reason { get; set; } = "";
        public object CurrentValue { get; set; }

        public static SourceFieldAccess ReadOnly(string propertyName, string reason) => new SourceFieldAccess
        {
            PropertyName = propertyName ?? "",
            Editable = false,
            Reason = reason ?? "",
            CurrentValue = null
        };
    }
}
