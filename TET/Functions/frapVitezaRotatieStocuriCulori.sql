--***
create function dbo.frapVitezaRotatieStocuriCulori()
returns @culori table(culoare varchar(20), calificativ varchar(20),
	zi_jos int,	--> limita inferioara a intervalului
	zi_sus int	--> limita superiorara a intervalului
	)
as
begin
	if exists (select 1 from sysobjects where name='frapVitezaRotatieStocuriCuloriSP')
	begin
		insert into @culori(culoare, calificativ, zi_jos, zi_sus) select culoare, calificativ, zi_jos, zi_sus from dbo.frapVitezaRotatieStocuriCuloriSP
		return
	end
	insert into @culori(culoare, calificativ, zi_jos, zi_sus)
	select '#FFCC66','si bine si rau',-9999999,21 union all
	select 'LightGreen','bine',21,52 union all
	select 'Yellow','slabut',52,91 union all
	select '#ff9999','foarte rau',91,9999999
	return
end
