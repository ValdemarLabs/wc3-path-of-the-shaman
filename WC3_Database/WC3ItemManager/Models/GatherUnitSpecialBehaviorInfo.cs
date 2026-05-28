using System.Collections.Generic;

namespace WC3ItemManager.Models
{
    public sealed class GatherUnitSpecialBehaviorOption
    {
        public int Id { get; set; }
        public string Name { get; set; }

        public override string ToString() => Name;
    }

    public static class GatherUnitSpecialBehaviorInfo
    {
        public const int None = 0;
        public const int ManaCrystalExplosion = 1;

        public static readonly IReadOnlyList<GatherUnitSpecialBehaviorOption> Options =
            new List<GatherUnitSpecialBehaviorOption>
            {
                new GatherUnitSpecialBehaviorOption { Id = None, Name = "None" },
                new GatherUnitSpecialBehaviorOption { Id = ManaCrystalExplosion, Name = "Mana Crystal Explosion" }
            };

        public static string GetName(int id)
        {
            foreach (var option in Options)
            {
                if (option.Id == id)
                {
                    return option.Name;
                }
            }

            return "None";
        }
    }
}
