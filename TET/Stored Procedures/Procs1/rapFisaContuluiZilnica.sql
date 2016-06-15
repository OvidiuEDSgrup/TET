--***
create procedure rapFisaContuluiZilnica @sesiune varchar(50)='',
	@DataJos datetime,@DataSus datetime,
	@PeJurnale bit=0,
	@CCont nvarchar(4000)='',@CuSoldRulaj bit=1, @EOMDataSus datetime=null, @locm varchar(20)=null,
	@valuta varchar(20) = null, @inValuta bit = 0
as

declare @eroare varchar(max)
select @eroare=''

begin try
set transaction isolation level read uncommitted
if object_id('tempdb..#fisa') is not null drop table #fisa
if object_id('tempdb..#fisaZilnic') is not null drop table #fisaZilnic

if object_id('tempdb..#fisa') is null
begin
	create table #fisa(cont varchar(100))
	exec rapFisaContului_tabela
end

exec rapFisaContului @subtotaluri =0, @DataJos=@DataJos, @DataSus=@DataSus, @CCont=@CCont, @CuSoldRulaj=1,
	@EOMDataSus=@EOMDataSus, @locm=@locm, @intabela=1

select data, cont, (case when cont=cont_debitor then cont_creditor else cont_debitor end) cont_corespondent, tip_document, numar, explicatii,
	isnull(suma_deb,0) suma_deb, isnull(suma_cred,0) suma_cred, isnull(sold_deb,0)-isnull(sold_cred,0) as sold_ant, isnull(sold_deb,0)-isnull(sold_cred,0) as sold
	,convert(int,0) as ordineZi, isnull(sold_deb,0)-isnull(sold_cred,0) as sold_detalii, denumire_cont
into #fisaZilnic
	from #fisa f where are_analitice=0

--> index pentru ordonarea tabelei; e necesar pentru cumularea soldului prin update:
create clustered index ind on #fisaZilnic(data, cont, cont_corespondent)

--> calculez soldurile cumulate, doar pentru prima inregistrare din fiecare zi:
	declare @sold decimal(18,3), @sold_prec decimal(18,3), @data datetime, @rand int
	select @sold=0, @rand=0, @data='2999-1-1'
	update f set
				--f.sold_ant=(case when f.ordineZi=1 then @sold+f.sold-(f.suma_deb-f.suma_cred) else f.sold_ant end),
				--f.sold=@sold
				@rand=(case when @data=f.data then @rand+1 else 1 end)
				,ordineZi=(case when @data=f.data then @rand else ordineZi end)
				,@sold_prec=(case when @data<>f.data then @sold else sold end)
				,@sold=@sold+f.sold+f.suma_deb-f.suma_cred
				,f.sold_ant=@sold_prec--(case when f.ordineZi=1 then @sold else f.sold end)
				,f.sold_detalii=@sold
				,@data=f.data
	from #fisaZilnic f

	update f set f.sold=f.sold_ant+ff.soldZi
	from #fisaZilnic f cross apply(select sum(ff.suma_deb-ff.suma_cred) soldZi from #fisaZilnic ff where ff.data=f.data) ff
		where f.ordinezi=1

	--> mica modificare pentru a putea afisa in ultima linie a raportului soldul final:
	declare @maxzi datetime
	select @maxzi=max(data) from #fisaZilnic
	update f set ordinezi=0
	from #fisazilnic f where f.data=@maxzi and f.ordinezi=1

	select * from #fisaZilnic where data>'1901-1-1'
		--> ordonarea a fost stabilita mai sus, prin intermediul indexului necesar oricum si pentru update-ul soldului cumulat
end try
begin catch
	select @eroare=error_message()+'('+ OBJECT_NAME(@@PROCID)+')'
end catch
if object_id('tempdb..#fisa') is not null drop table #fisa
if object_id('tempdb..#fisaZilnic') is not null drop table #fisaZilnic
if len(@eroare)>0 raiserror(@eroare,16,1)
