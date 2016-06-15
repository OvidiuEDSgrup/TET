--***
create procedure wScriuUtilaj @sesiune varchar(50), @parXML xml
as 
if exists (select 1 from sys.objects where name='wScriuUtilajSP' and type='P')  
	exec wScriuUtilajSP @sesiune, @parXML
else  
begin  

declare	@codMasina varchar(20), @tipMasina varchar(20), @nr_inmatriculare varchar(15), @serieCaroserie varchar(100),
@denumire varchar(40), @nr_inventar varchar(13), @grupa varchar(3), @lm varchar(9), @comanda varchar(20), 
@update int, @mesajeroare varchar(max), @OREBORDImpl float, @RestDeclImpl float
, @CO float, @cIarna float, @cVara float, @cRezervor float

DECLARE @utilizator VARCHAR(50)
EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
IF @utilizator IS NULL
	RETURN -1

begin try
select 
	@codMasina=ISNULL(@parXML.value('(/row/@codMasina)[1]', 'varchar(20)'), ''), 
	@nr_inmatriculare=ISNULL(@parXML.value('(/row/@nr_inmatriculare)[1]', 'varchar(15)'), ''), 
	@denumire=ISNULL(@parXML.value('(/row/@denumire)[1]', 'varchar(40)'), ''), 
	@nr_inventar=ISNULL(@parXML.value('(/row/@nr_inventar)[1]', 'varchar(13)'), ''), 
	@serieCaroserie=ISNULL(@parXML.value('(/row/@serieCaroserie)[1]', 'varchar(100)'), ''), 
	@OREBORDImpl=ISNULL(@parXML.value('(/row/@OREBORDImpl)[1]', 'float'), ''), 
	@RestDeclImpl=ISNULL(@parXML.value('(/row/@RestDeclImpl)[1]', 'float'), ''), 
	@CO=ISNULL(@parXML.value('(/row/@CO)[1]', 'float'), ''), 
	@cIarna=ISNULL(@parXML.value('(/row/@cIarna)[1]', 'float'), ''), 
	@cVara=ISNULL(@parXML.value('(/row/@cVara)[1]', 'float'), ''), 
	@cRezervor=ISNULL(@parXML.value('(/row/@cRezervor)[1]', 'float'), ''), 
	@update=ISNULL(@parXML.value('(/row/@update)[1]', 'int'), ''),
	@comanda=ISNULL(@parXML.value('(/row/@comanda)[1]', 'varchar(20)'), ''),
	@grupa=ISNULL(@parXML.value('(/row/@grupa)[1]', 'varchar(20)'), ''),
	@lm=ISNULL(@parXML.value('(/row/@denlm)[1]', 'varchar(20)'), '')
		
set @tipMasina=(select max(g.tip_masina) from grupemasini g where g.Grupa=@grupa)

select @mesajeroare = coalesce(@mesajeroare,'')+ 
(case	when @codMasina='' and @update=1 then 'Cod masina necompletat!' + CHAR(10)
		when @denumire='' then 'Descrirere masina necompletata!' + CHAR(10)
		when @tipMasina='' then 'Tipul masinii nu poate fi determinat!' + CHAR(10)
		else '' 
end)

if @mesajeroare<>''
	raiserror (@mesajeroare,11,1)

/* scriu in tabela masini */
if @update=0 /* masina noua*/
begin
	set @codMasina = isnull( (select MAX(convert(int,cod_masina)) from masini where ISNUMERIC(cod_masina)=1 ) , 0) + 1
	insert into masini(cod_masina, tip_masina,nr_inmatriculare,denumire,nr_inventar, capacitate_metri_cubi, consum_normat_100km,
		consum_pe_ora,grupa,loc_de_munca,coeficient,tonaj, benzina_sau_motorina, capacitate_rezervor, capacitate_baie_de_ulei,
		norma_de_ulei,consum_vara, consum_iarna, consum_usor, consum_mediu, consum_greu, km_la_bord_efectivi, km_la_bord_echivalenti,
		km_SU, km_RK, km_RT1, km_RT2, ultim_SU, ultim_RK, ultim_RT1, ultim_RT2, de_care_masina, de_putere_mare, Comanda, 
		data_expirarii_ITP, Firma_CASCO, Serie_caroserie)	
		values (@codMasina, @tipMasina, @nr_inmatriculare, @denumire, @nr_inventar, 0, 0, 
		0, @grupa, @lm, 0, 0, '', 0, 0, 
		0, 0, 0, 0, 0, 0, 0, 0, 
		0, 0, 0, 0, '01/01/1901', '01/01/1901', '01/01/1901', '01/01/1901', '', '', @comanda, 
		'01/01/1901', '', '')
end
else	/* masina existenta */
	if exists (select 1 from masini where cod_masina=@codMasina)
			update masini 
				set denumire=@denumire, tip_masina=@tipMasina, nr_inmatriculare=@nr_inmatriculare, 
					nr_inventar=@nr_inventar, comanda=@comanda ,loc_de_munca=@lm, grupa=@grupa
			where cod_masina=@codMasina
	else raiserror('Codul masinii nu poate fi gasit!',11,1)

/* scriu valori implementare */
delete from valelemimpl where Masina=@codMasina and element in ('RestDecl', 'OREBORD')

insert into valelemimpl (Masina, Element, Valoare) values (@codMasina, 'RestDecl', @RestDeclImpl)
insert into valelemimpl (Masina, Element, Valoare) values (@codMasina, 'OREBORD', @OREBORDImpl)

/* scriu coeficienti */
delete from coefmasini where Masina=@codMasina and Coeficient in ('CO', 'cIarna', 'cVara', 'cRezervor')
insert into coefmasini (Masina, Coeficient, Valoare, Interval) 
values (@codMasina, 'CO', @CO, 100)
insert into coefmasini (Masina, Coeficient, Valoare, Interval) 
values (@codMasina, 'cIarna', @cIarna, 0)
insert into coefmasini (Masina, Coeficient, Valoare, Interval) 
values (@codMasina, 'cVara', @cVara, 0)
insert into coefmasini (Masina, Coeficient, Valoare, Interval) 
values (@codMasina, 'cRezervor', @cRezervor, 0)
 
end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
end


