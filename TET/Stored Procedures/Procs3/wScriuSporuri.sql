--***
create procedure wScriuSporuri @sesiune varchar(50), @parXML xml
as 

Declare @codMeniu varchar(2), @iDoc int, @ptupdate int, @marca varchar(6), 
@DouaNivele int, @RowPattern varchar(20), @PrefixAtrMarca varchar(3), @AtrMarca varchar(20), 
@eroare int, @mesaj varchar(254), @mesajEroare varchar(254), @varmesaj varchar(254)

set @codMeniu=isnull(@parXML.value('(/row/@codMeniu)[1]','varchar(2)'),'')
select @DouaNivele = @parXML.exist('/row/row'), 
	@RowPattern = '/row' + (case when @DouaNivele=1 then '/row' else '' end), 
	@PrefixAtrMarca = (case when @DouaNivele=1 then '../' else '' end), 
	@AtrMarca = @PrefixAtrMarca + '@marca'

EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
IF OBJECT_ID('tempdb..#xmlsporuri') IS NOT NULL
	drop table #xmlsporuri
IF OBJECT_ID('tempdb..#personalFiltrat') IS NOT NULL 
	drop table #personalFiltrat

begin try  

	select isnull(ptupdate, 0) as ptupdate, marca, 
	salinc, isnull(nullif(salbaza,0),salinc) as salbaza, spvech, spnoapte, spprogr, spsupl, spindc, spspec, sp1, sp2, sp3, sp4, sp5, sp6, sp7
	into #xmlsporuri
	from OPENXML(@iDoc, @RowPattern)
	WITH
	(
		ptupdate int '@update',
		marca varchar(6) @AtrMarca,
		salinc decimal(10) '@salinc',
		salbaza decimal(10) '@salbaza',
		spvech decimal(8,2) '@spvech',
		spnoapte decimal(8,2) '@spnoapte',
		spprogr decimal(8,2) '@spprogr',
		spsupl decimal(8,2) '@spsupl',
		spindc decimal(8,2) '@spindc',
		spspec decimal(8,2) '@spspec',
		sp1 decimal(8,2) '@sp1',
		sp2 decimal(8,2) '@sp2',
		sp3 decimal(8,2) '@sp3',
		sp4 decimal(8,2) '@sp4',
		sp5 decimal(8,2) '@sp5',
		sp6 decimal(8,2) '@sp6',
		sp7 decimal(8,2) '@sp7'
	)
	exec sp_xml_removedocument @iDoc 

	if @eroare<>0
	Begin
		raiserror(@mesajEroare, 16, 1)
	End

--	calcul salar de baza in tabela temporara. Se va scrie salarul de baza in personal impreuna cu celelalte informatii.
	if object_id('tempdb..#personalSalBaza') is not null
		drop table #personalSalBaza
	Create table #personalSalBaza (marca varchar(6) not null)
	exec CreeazaDiezPersonal @numeTabela='#personalSalBaza'
	insert into #personalSalBaza
	select marca, salinc as salar_de_incadrare, salbaza as salar_de_baza, spindc as indemnizatia_de_conducere, spspec as spor_specific, 
		sp1 as spor_conditii_1, sp2 as spor_conditii_2, sp3 as spor_conditii_3, sp4 as spor_conditii_4, sp5 as spor_conditii_5, sp6 as spor_conditii_6
	from #xmlsporuri
	exec calculSalarDeBaza @sesiune=@sesiune, @parXML=@parXML
	update #xmlsporuri set salbaza=isnull(nullif(#personalSalBaza.salar_de_baza,0),#xmlsporuri.salbaza)
	from #personalSalBaza 
	where #personalSalBaza.marca=#xmlsporuri.marca

--	update
	update p
	set	p.Salar_de_baza=isnull(nullif(x.salbaza,0),p.Salar_de_baza),
		p.Spor_vechime=isnull(x.spvech,p.Spor_vechime), p.Spor_de_noapte=isnull(x.spnoapte,p.Spor_de_noapte),
		p.Spor_sistematic_peste_program=isnull(x.spprogr,p.Spor_sistematic_peste_program), p.Spor_de_functie_suplimentara=isnull(x.spsupl,p.Spor_de_functie_suplimentara),
		p.Indemnizatia_de_conducere=isnull(x.spindc,p.Indemnizatia_de_conducere), p.Spor_specific=isnull(x.spspec,p.Spor_specific), Spor_conditii_1=isnull(x.sp1,p.Spor_conditii_1), 
		p.Spor_conditii_2=isnull(x.sp2,p.Spor_conditii_2), p.Spor_conditii_3=isnull(x.sp3,p.Spor_conditii_3), p.Spor_conditii_4=isnull(x.sp4,p.Spor_conditii_4), 
		p.Spor_conditii_5=isnull(x.sp5,p.Spor_conditii_5), p.Spor_conditii_6=isnull(x.sp6,p.Spor_conditii_6)
	from personal p, #xmlsporuri x
	where x.ptupdate=1 and p.marca=x.marca

	select marca into #personalFiltrat from #xmlsporuri
	exec calculSalarDeBaza @sesiune=@sesiune, @parXML=@parXML

	update i
	set Spor_cond_7=isnull(x.sp7,i.spor_cond_7)
	from infopers i, #xmlsporuri x
	where x.ptupdate=1 and i.Marca=x.Marca

	if @codMeniu='SSP'
		select 0 as 'close' for xml raw, root('Mesaje')

end try  
begin catch
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch

IF OBJECT_ID('tempdb..#xmlsporuri') IS NOT NULL
	drop table #xmlsporuri
