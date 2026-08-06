namespace NF.Dotnetlibs.AI.Pathfinder;

public interface IMap
{
    void SetWallAt(int x, int y, bool isWall);
    void SetEmptyAt(int x, int y, bool isEmpty);
}
