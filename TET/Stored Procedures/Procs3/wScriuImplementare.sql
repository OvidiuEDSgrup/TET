--
create procedure  dbo.wScriuImplementare @sesiune varchar(50), @parXML XML
as

declare @eroare varchar(4000)
begin try 
	declare @tipFisa varchar(2), @masina varchar(20), @comanda varchar(20), @data datetime, @fisa varchar(20), 
		@numar_pozitie int, @element varchar(20), @valoare float, @loc_de_munca varchar(9),@utilizator VARCHAR(50),@update int,
		@bord decimal(15,2), @o_tipFisa varchar(2), @o_fisa varchar(20), @o_data datetime
	--Initializare variabile
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	Select	@tipFisa= isnull(@parXML.value('(/row/row/@tipFisa)[1]','varchar(2)'),''),
			@data= @parXML.value('(/row/row/@data)[1]','varchar(20)'),
			@numar_pozitie= isnull(@parXML.value('(/row/row/@numar_pozitie)[1]','int'),0),
			@element= isnull(@parXML.value('(/row/row/@element)[1]','varchar(20)'),''),
			@valoare= isnull(@parXML.value('(/row/row/@valoare)[1]','float'),0),
			@bord=isnull(@parXML.value('(/row/row/@bord)[1]', 'decimal(15,2)'), 0),
			@masina= isnull(@parXML.value('(/row/@codMasina)[1]','varchar(20)'),''),
			@fisa= 'I'+rtrim(@masina),
			@comanda= @parXML.value('(/row/@comanda)[1]','varchar(20)'),
			@loc_de_munca= isnull(@parXML.value('(/row/@lm)[1]','varchar(9)'),''),
			--> urmatoarele trei variabile se folosesc la update pe coloanele de identificare a fisei:
			@o_tipFisa= @parXML.value('(/row/row/@o_tipFisa)[1]','varchar(2)'),
			@o_fisa= @parXML.value('(/row/row/@o_fisa)[1]','varchar(20)'),
			@o_data= @parXML.value('(/row/row/@o_data)[1]','varchar(20)')
			,@update=isnull(@parXML.value('(/row/@update)[1]', 'int'), 0)
	select @o_tipFisa=isnull(@o_tipFisa,@tipFisa), @o_fisa=isnull(@o_fisa,@fisa), @o_data=isnull(@o_data,@data)
	--Validari diverse
	--	if @valoare=0 raiserror('Introduceti o valoare diferita de 0!',16,1)	--> exista elemente (de exemplu CASCO) pentru care valoarea nu conteaza
	if @tipFisa not in ('FI','FP','FL')
		raiserror('Introduceti tipul de document!',16,1)
	if @tipFisa='FI' and @element in ('KmBord','ORENOU')
		raiserror('La Tip Document = Fisa de interventie nu se permit elemente de tip KmBord sau ORENOU!',16,1)
/*	if @tipFisa='FP' and @element not in ('KmBord','RestEst')
		raiserror('La Tip Document = Foaie de parcurs elementul nu poate fi decat KmBord=Kilometri la bord sau RestEst=Rest estimat!',16,1)
	if @tipFisa='FL' and @element not in ('ORENOU','RESTESTU')
		raiserror('La Tip Document = Fisa de lucru elementul nu poate fi decat ORENOU=Ore lucrate (total ore lucrate pana in prezent) sau RESTESTU=Rest estimat in rezervor!',16,1)*/
	if @masina=''
		raiserror('Nu s-a identificat masina!',16,1)

	declare @tip_activitate varchar(20)
	select @tip_activitate=t.Tip_activitate 
	from masini m 
	inner join grupemasini g on m.grupa=g.Grupa
	inner join tipmasini t on g.tip_masina=t.Cod
	where m.cod_masina=@masina

		--> formare xml pentru wScriuElemActivitati:
	declare @parXML2 xml
	select @parXML2=(select @tipFisa tip, @fisa fisa, @data data, @masina masina, @comanda comanda, @loc_de_munca lm, 1 as implementare,
						@o_tipFisa o_tip, @o_fisa o_fisa, @o_data o_data,
						(select @numar_pozitie [@numar_pozitie], @element [@element], @tipFisa [@subtip], @valoare [@valoare],
							--@element [@interventie],
							(case when @tip_activitate='L' then @bord else null end) as [@OREBORD], 
							(case when @tip_activitate='P' then @bord else null end) [@KmBord], @valoare [@deInlocuitCuNumeleDinElement], @element [@interventie]
							,@update [@update]
							for xml path, type)
				 for xml raw)
	select @parXML2=convert(xml,replace(convert(varchar(3000),@parXML2),'deInlocuitCuNumeleDinElement',@element))
	exec wScriuPozActivitati @sesiune=@sesiune, @parXML=@parXML2
end try
begin catch
	set @eroare=error_message()+'(MM/wScriuImplementare '+convert(varchar(20),error_line())+')'
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)

		--> datorita metodei complicate de scriere a datelor in MM e de preferat sa se scrie prin apelul 
		-->	lui wScriuElemActivitati
