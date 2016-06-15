--***
Create function fTip_ConcediiAlte()
returns @tip_concediialte table
	(tip_concediu char(2), denumire char(30), ore_pontaj char(30), prescurtare varchar(3))
as
begin
	declare @oresupl1 int, @oresupl2 int, @oresupl3 int, @oresupl4 int, 
		@den_os1 char(20),@den_os2 char(20),@den_os3 char(20),@den_os4 char(20)

	select @oresupl1=max((case when Parametru='OSUPL1' then val_logica else 0 end)), 
		@den_os1=max((case when Parametru='OSUPL1' then rtrim(val_alfanumerica)+' '+ltrim(rtrim(str(val_numerica,6,2)))+'%' else '' end)), 
		@oresupl2=max((case when Parametru='OSUPL2' then val_logica else 0 end)), 
		@den_os2=max((case when Parametru='OSUPL2' then rtrim(val_alfanumerica)+' '+ltrim(rtrim(str(val_numerica,6,2)))+'%' else '' end)),
		@oresupl3=max((case when Parametru='OSUPL3' then val_logica else 0 end)), 
		@den_os3=max((case when Parametru='OSUPL3' then rtrim(val_alfanumerica)+' '+ltrim(rtrim(str(val_numerica,6,2)))+'%' else '' end)), 
		@oresupl4=max((case when Parametru='OSUPL4' then val_logica else 0 end)), 
		@den_os4=max((case when Parametru='OSUPL4' then rtrim(val_alfanumerica)+' '+ltrim(rtrim(str(val_numerica,6,2)))+'%' else '' end))
	from par where Tip_parametru='PS' and Parametru in ('OSUPL1','OSUPL2','OSUPL3','OSUPL4')

	insert @tip_concediialte
	select '1', 'Concediu fara salar', 'Ore_concediu_fara_salar', 'FS'
	union all
	select '2', 'Nemotivate', 'Ore_nemotivate', 'NE'
	union all 
	select '3', 'Invoiri', 'Ore_invoiri', 'IV'
	union all
	select '4', 'Delegatie', 'Spor_cond_10', 'DL'
	union all
	select '5', 'Perioada de proba', '', 'PB'
	union all
	select '6', 'Preaviz', '', 'PZ'
	union all
	select '9', 'Cercetare disciplinara', '', 'CD'
	union all
	select 'F', 'Formare profesionala', '', 'FP'
	union all
	select 'R', 'Recuperare', (case when 1=1 then 'Ore' else '' end), 'RE'
	union all
	select 'D', 'Detasare', 'Spor_cond_9', 'DT'
	union all
	select 'M', 'Anunt concediu medical', '', 'AM'
	union all
	select 'H', 'Lucrat de acasa', 'Ore_regie', 'HO'
	union all
	select 'A', @den_os1, 'Ore_suplimentare_1', 'S1' where @oresupl1=1
	union all
	select 'B', @den_os2, 'Ore_suplimentare_2', 'S2' where @oresupl2=1
	union all
	select 'C', @den_os3, 'Ore_suplimentare_3', 'S3' where @oresupl3=1
	union all
	select 'D', @den_os4, 'Ore_suplimentare_4', 'S4' where @oresupl4=1
	union all
	select 'E', 'Ore spor 100%', 'Ore_spor_100', 'SP'
	union all
	select 'N', 'Ore de noapte', 'Ore_de_noapte', 'NO'
	return 
end
