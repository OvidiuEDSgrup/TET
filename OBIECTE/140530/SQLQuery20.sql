select 'exec SP_MOVE_TABLES @SourceFileGroupID = 1, @TargetFileGroupID = 2, @TableToMove = '''+quotename(o.name)+'''',* 
from sys.objects o where o.type='u' and o.name like 'syss%' 
order by o.name