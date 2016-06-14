--***
if exists (select * from sysobjects where name ='tr_RezervaLaIntrareInStocSP ' and xtype='TR')
	drop trigger tr_RezervaLaIntrareInStocSP 
go
--***
create trigger tr_RezervaLaIntrareInStocSP on pozdoc after insert,update,delete
as
BEGIN TRY
/*
	Se presupune ca acest trigger (se va seta ordinea daca este cazul) se executa dupa DOCSTOC pt. ca intotdeauna sa functioneze 
		INNER JOIN-UL pe stocuri (chiar si cand e prima intrare pe o gestiune, cod...)
*/
if exists (select * from sysobjects where name ='RezervaLaIntrareInStocSP')
begin
	declare @gestiuneRezervari varchar(20)
	--EXEC luare_date_par 'GE', 'REZSTOCBK', 0, 0, @gestiuneRezervari OUTPUT

	select 'I' as tiplinie,i.data,i.cod,i.gestiune,sum(i.Cantitate) as cantitate, i.Cod_intrare,
		i.[Contract]
	into #tmpderezervatRN
	from inserted i 
	--inner join stocuri s on i.Gestiune=s.Cod_gestiune and i.cod=s.cod
	where --/*SP  and not (i.tip='TE' and i.gestiune_primitoare=@gestiuneRezervari)  
	-- Aici ignoram si documentele care reprezinta valorificari de inventar. Ele sunt sit. exceptionale care nu dau efect in rez. automata
	i.Tip_miscare!='V' and ISNULL(i.detalii.value('(/row/@_nuRezervaStoc)[1]','int'),0)=0 and detalii.value('(/row/@idInventar)[1]','int') IS NULL --/*SP
	AND i.Subunitate='1' and i.Tip='RM' and i.Gestiune='101' and i.Contract<>''--*SP/
	group by i.data,i.cod,i.gestiune, i.Cod_intrare, i.Contract /*SP
	union all
	select 'I' as tiplinie,i.data,i.cod,i.Gestiune_primitoare,sum(s.stoc) as cantitate
	from inserted i
	inner join stocuri s on i.Gestiune_primitoare=s.Cod_gestiune and i.cod=s.cod
	where i.Tip_miscare!='V' and i.tip='TE' and i.gestiune_primitoare<>@gestiuneRezervari and ISNULL(i.detalii.value('(/row/@_nuRezervaStoc)[1]','int'),0)=0 
	-- Aici ignoram si documentele care reprezinta valorificari de inventar. Ele sunt sit. exceptionale care nu dau efect in rez. automata
	and detalii.value('(/row/@idInventar)[1]','int') IS NULL 
	--SP* and i.Gestiune_primitoare='101' 
	group by i.data,i.cod,i.Gestiune_primitoare --SP*/


	if @@ROWCOUNT>0
		exec RezervaLaIntrareInStocSP
end
END TRY
BEGIN CATCH
	declare @mesaj varchar(600)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
go
declare @cuRezervari int
set @cuRezervari=0
select top 1 @cuRezervari=val_logica from par where tip_parametru='GE' and parametru='REZSTOCBK'
if @cuRezervari=0
	drop trigger tr_RezervaLaIntrareInStocSP
go
declare @cuRezervariManuale int
set @cuRezervariManuale=0
select top 1 @cuRezervariManuale=val_logica from par where tip_parametru='GE' and parametru='REZSTOCM'
if @cuRezervariManuale=1
	drop trigger tr_RezervaLaIntrareInStocSP
go