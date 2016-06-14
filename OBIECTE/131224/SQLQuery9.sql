set transaction isolation level read uncommitted
EXEC sp_MSForeachdb 'if exists (select 1 from [?].sys.objects o where o.name=''webconfigtipuri'') 
if exists (SELECT top 1 1 from [?]..webConfigTipuri t where ''wOPDeschidereActAditionalContract''
in (ProcScriere)) 
SELECT ''?'',* from [?]..webConfigTipuri t where ''wOPDeschidereActAditionalContract''
in (ProcScriere)'
--select * from webConfigSTDTipuri t where 'wOPVizualizareActAditionalContract_p' in 
--use ghita_modistru
--select * from webConfigTipuri t where t.Meniu='PV'
--exec exportMeniuRia @tipMacheta='D', @meniu='PV', @tip='PV', @subtip=''