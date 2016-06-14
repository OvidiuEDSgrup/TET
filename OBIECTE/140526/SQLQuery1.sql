--sp_blitzindex
EXEC dbo.sp_BlitzIndex @DatabaseName='TET', @SchemaName='dbo', @TableName='con';
--CREATE INDEX [missing_index_2239] ON [dbo].[stocuri] ( [Tip_gestiune] ) INCLUDE ( [Cod], [Cod_gestiune], [Cod_intrare], [Subunitate], [Stoc]) 
--CREATE INDEX missing_index_3 ON [TET].[dbo].[stocuri] ([Tip_gestiune]) INCLUDE ([Cod_gestiune], [Cod], [Stoc])			
CREATE INDEX [missing_index_2088] ON [dbo].[con] ( [Subunitate], [Tert], Tip ) --WITH (FILLFACTOR=100, ONLINE=?, SORT_IN_TEMPDB=?);