/*
	Adauga toate atributele din un XML (momentan hard-codat ca element <row />) in alt XML destinatie(tot in /row).
	
	* la nevoie, se va putea parametriza functia, pentru a citi/scrie atributele si in alte noduri, nu doar in radacina /row.
	* Deoarece nu se poate face in aceeasi comanda face si insert si replace la atribute(replace trebuie sa fie singura), 
		zona pentru replace se face cu un cursor.
	* in SQL server 2008 sau mai vechi, nu se pot specifica numele atributelor in mod dinamic, si problema se rezolva folosind dynamic SQL.
	* @extrageDetalii daca e 1, extrage doar atributele cu care incep cu @detalii_, si creaza tribute fara acest prefix.
*/
create procedure adaugaAtributeXml @xmlSursa xml, @xmlDest XML output, @debug bit=0, @extrageDetalii bit=0
as  
declare @mesaj varchar(1000), @command nvarchar(max), @antetComanda varchar(max), @finalComanda varchar(max)
declare @atrTable table(nume varchar(50), valoare varchar(50), pt_update bit)

set nocount on

begin try
	if @xmlSursa is null 
		return
	if @xmlDest is null
		set @xmlDest='<row />'
	
	-- citesc atributele din documentul sursa
	insert into @atrTable(nume, valoare, pt_update)	
	SELECT
		xA.atribut.value('localname[1]', 'varchar(50)') AS nume,
		xA.atribut.value('value[1]', 'varchar(50)') AS valoare,
		0 pt_update
	FROM 
	( 
	SELECT x.query('
			for $attr in /row/@*
			return
			<atribute>
			  <localname>{ local-name($attr) }</localname>
			  <value>{ data($attr) }</value>
			</atribute>') AS atribute
		FROM @xmlSursa.nodes('/row') x(x)
		) q1
		CROSS APPLY q1.atribute.nodes('/atribute') AS xA(atribut)
		where xA.atribut.value('localname[1]', 'varchar(50)') not like 'o_%'
	
	if @extrageDetalii=1
	begin
		delete from @atrTable where nume not like 'detalii_%'
		
		update @atrTable set nume = SUBSTRING(nume, 9, LEN(nume))
	end
	
	-- verific existenta atributelor in xmlDestinatie
	-- pentru ca sa stiu daca se da insert sau replace
	update @atrTable
		set pt_update=1
	from @atrTable a,
		(SELECT
			xA.atribut.value('localname[1]', 'varchar(50)') AS nume,
			xA.atribut.value('value[1]', 'varchar(50)') AS valoare,
			1 pt_update
		FROM 
		(SELECT x.query('
				for $attr in /row/@*
				return
				<atribute>
				  <localname>{ local-name($attr) }</localname>
				  <value>{ data($attr) }</value>
				</atribute>') AS atribute
			FROM @xmlDest.nodes('/row') x(x)
			) q1
			CROSS APPLY q1.atribute.nodes('/atribute') AS xA(atribut)
			where xA.atribut.value('localname[1]', 'varchar(50)') not like 'o_%' ) x
	where x.nume=a.nume
	
	if @debug=1
		select * from @atrTable
	
	-- construiesc comanda pentru insert
	if exists (select * from @atrTable where pt_update=0)
	begin
		SET @antetComanda = 'SET @xmlDest.modify(''insert ('+CHAR(13)
		
		set @command=''
		select @command= @command + ' attribute '+a.nume+' {"'+replace(a.valoare,'''','''''')+'"},'+char(13)
			from @atrTable a
			where a.pt_update=0
		
		set @finalComanda=') into (/row[1])'')'
	
		set @command=@antetComanda+substring(@command,1, len(@command)-2)+@finalComanda 
	end
	
	-- construiesc comanda pentru update
	-- update trebuie sa fie comanda separata in @xml.modify...
	if exists (select * from @atrTable where pt_update=1)
	begin
		SET @command = isnull(@command,'')+char(13)
		declare @crsPoz cursor, @nume varchar(100), @valoare varchar(100)
		
		-- fac un cursor cu toate valorile la care trebuie replace 
		set @crsPoz = cursor local fast_forward for
			select nume,valoare
				from @atrTable where pt_update=1
		
		open @crsPoz
		fetch next from @crsPoz into @nume, @valoare
		while @@FETCH_STATUS=0
		begin
			SET @command = isnull(@command,'')+char(13)+
				'SET @xmlDest.modify(''replace value of /row[1]/@'+@nume+' with "'+replace(@valoare,'''','''''')+'"'')'
			
			fetch next from @crsPoz into @nume, @valoare
		end
		if CURSOR_STATUS('variable','@crsPoz') >= 0
			close @crsPoz
		if CURSOR_STATUS('variable','@crsPoz') >= -1
			deallocate @crsPoz
	end
	
	if @debug=1 
		print @command
	
	if len(@command)>0
		EXEC sp_executesql @stmt = @command,
						   @params = N'@xmlDest xml out',
						   @xmlDest = @xmlDest OUTPUT
	
end try
begin catch
	set @mesaj = ERROR_MESSAGE()+' (adaugaAtributeXml)'
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)

/*

declare @xmlSursa xml, @xmlDest XML  
set @xmlSursa='<row iddisp="2" descriere="una" stare="In lucru" tip="IN" tipMacheta="D" codMeniu="DR" TipDetaliere="IN" subtip="GR" cu_inserare_lipsa="1" o_iddisp="2" o_descriere="una" o_stare="In lucru" o_tip="IN" o_tipMacheta="D" o_codMeniu="DR" o_TipDetaliere="IN" o_subtip="GR" o_cu_inserare_lipsa="1" update="1" gestiune="1" gestiune_sparturi="2" gestiune_lipsa="3" data_receptie="09/03/2012" tert="3504649" lm="101" factura="12345" data_facturii="09/03/2012"/>'
set @xmlDest='<row iddisp="mitztest" />'

exec adaugaAtributeXml @xmlSursa, @xmlDest output

select @xmlDest

*/
