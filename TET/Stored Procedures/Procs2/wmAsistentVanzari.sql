CREATE procedure wmAsistentVanzari @sesiune varchar(50), @parXML xml
as
begin
	declare 
		@utilizator varchar(100), @comanda int, @tert varchar(13), @cu_contract xml, @tert_general xml, @comandaNoua bit, @tert_gen varchar(20)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	set @comanda=@parXML.value('(/*/@comanda)[1]','int')
	set @tert=@parXML.value('(/*/@tert)[1]','varchar(20)')
	set @comandaNoua=ISNULL(@parXML.value('(/*/@comandaNoua)[1]','bit'),0)
	if @utilizator is null
		return -1

	/** Identificare ultima comanda nefinalizata a agentului de vanzari **/
	IF @comanda IS NULL
		select top 1 
			@comanda=idContract, @tert=tert
		from (
				select
					c.idContract,c.tert,jc.stare, jc.utilizator,RANK() over (partition by c.idContract order by jc.data desc, jc.idJurnal desc) rn,
					c.data
				from Contracte c
					JOIN JurnalContracte jc on jc.idContract=c.idContract 
				where tip='CL' and tert is not null
			) cst where	cst.stare='0' and cst.utilizator=@utilizator and cst.rn=1 and DATEDIFF(day, cst.data, getdate())<=2
			order BY cst.idContract desc

	if isnull(@comanda,0)=0 OR @comandaNoua=1
	/* Daca nu are comanda nefinalizata-> afisez meniurile de adaugare comanda*/
	begin

		SELECT top 1 @tert_gen=Val_alfanumerica
		from par where Tip_parametru='UC' and Parametru='TERTGEN'

		set @tert_general=
		(
			select 
				@tert_gen as cod,'@tert' numeatr,  'Tert general' as denumire,'' as info,
				'0xFFFFFF' as culoare,'C' as tipdetalii, 'wmComandaAsistent' procdetalii,'assets/Imagini/Meniu/Contracte.png' as poza
			for xml raw, type
		)
		set @cu_contract=
		(
			select 
				'' as cod,'Tert cu contract' as denumire,'' as info,
				'0xFFFFFF' as culoare,
				'C' as tipdetalii, 'wmComandaAsistent' procdetalii,'assets/Imagini/Meniu/Terti2.png' as poza
			for xml raw, type
		)

		select @cu_contract, @tert_general
		for XML PATH('Date')
	end	
	else
	/** Daca s-a identificat o comanda, se apeleaza direct wmComandaLivrare cu parametri comanda si tert identificati**/
		begin
			
			if @parXML.exist('(/row/@comanda)[1]')=1
				set @parXML.modify('replace value of (/row/@comanda)[1] with sql:variable("@comanda")')                     
			else           
				set @parXML.modify ('insert attribute comanda {sql:variable("@comanda")} into (/row)[1]')
						
			if @parXML.exist('(/row/@tert)[1]')=1
				set @parXML.modify('replace value of (/row/@tert)[1] with sql:variable("@tert")')                     
			else           
				set @parXML.modify ('insert attribute tert{sql:variable("@tert")} into (/row)[1]') 	

			select @comanda as '@comanda', @tert as '@tert' for xml path('atribute'),root('Mesaje')
	
			select 
				(
					select
						'' as comanda,'1' as cod,'@comandaNoua' as numeatr,'Comanda noua' as denumire,
						'assets/Imagini/Meniu/AdaugProdus32.png' as poza,'' tert,
						'0x0000ff' as culoare,'wmAsistentVanzari' as _procdetalii, 'C' _tipdetalii, '1' _toateAtr
					FOR XML raw , type
				) 
			union all
			select 
				(	
				select
						cst.idContract comanda,ISNULL(cst.explicatii,'') as denumire,cst.tert tert,
						'assets/Imagini/Meniu/Contracte.png' as poza, '1' as _toateAtr,
						'0x0000ff' as culoare,'wmAsistentVanzari' as _procdetalii, 'C' _tipdetalii
					from (
							select
								c.idContract,c.tert,jc.stare, jc.utilizator, RANK() over (partition by c.idContract order by jc.data desc, jc.idJurnal desc) rn,
								c.numar numar, c.data, c.explicatii
							from Contracte c
								JOIN JurnalContracte jc on jc.idContract=c.idContract 
							where tip='CL' and isnull(c.tert,'')<>''
						) cst where	cst.stare='0' and cst.utilizator=@utilizator and cst.rn=1 and cst.idContract<>@comanda and DATEDIFF(day, cst.data, getdate())<=2
					order by cst.data desc
					FOR XML raw , type
					)
			for xml  raw ('meniu'), type ,Root('Mesaje')	

			exec wmComandaAsistent @sesiune=@sesiune,@parXML=@parXML
		end		
end	
