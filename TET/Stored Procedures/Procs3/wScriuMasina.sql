--***
create procedure wScriuMasina @sesiune varchar(50), @parXML xml
as 
if exists (select 1 from sys.objects where name='wScriuMasinaSP' and type='P')  
	exec wScriuMasinaSP @sesiune, @parXML
else  
begin  

declare	@codMasina varchar(20), @tipMasina varchar(20), @serieCaroserie varchar(100),
		--@nr_inmatriculare varchar(15), --> echivalent cod_masina
@denumire varchar(40), @nr_inventar varchar(13), @grupa varchar(3), @lm varchar(9), @comanda varchar(20), 
@update int, @mesajeroare varchar(max), @KmBordImpl float, @RestDeclImpl float, @C100 float, 
@cIarna float, @cVara float, @cKmEf1 float, @cKmEf2 float, @cKmEf3 float, @cRezervor float, @CO decimal(20,2),
@masina varchar(20), @coeficient varchar(50), @valoare float, @interval float,
	@o_codMasina varchar(20), @o_grupa varchar(3), @tipactivitate varchar(3)

DECLARE @utilizator VARCHAR(50)
EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
IF @utilizator IS NULL
	RETURN -1

begin try
select 
	@codMasina=ISNULL(@parXML.value('(/row/@codMasina)[1]', 'varchar(20)'), ''), 
	@denumire=ISNULL(@parXML.value('(/row/@denumire)[1]', 'varchar(40)'), ''), 
	@nr_inventar=ISNULL(@parXML.value('(/row/@nr_inventar)[1]', 'varchar(13)'), ''), 
	@serieCaroserie=ISNULL(@parXML.value('(/row/@serieCaroserie)[1]', 'varchar(100)'), ''), 
	@KmBordImpl=ISNULL(@parXML.value('(/row/@KmBordImpl)[1]', 'float'), ''), 
	@RestDeclImpl=ISNULL(@parXML.value('(/row/@RestDeclImpl)[1]', 'float'), ''), 
	@C100=ISNULL(@parXML.value('(/row/@C100)[1]', 'float'), ''), 
	@cIarna=ISNULL(@parXML.value('(/row/@cIarna)[1]', 'float'), ''), 
	@cVara=ISNULL(@parXML.value('(/row/@cVara)[1]', 'float'), ''), 
	@cKmEf1=ISNULL(@parXML.value('(/row/@cKmEf1)[1]', 'float'), ''), 
	@cKmEf2=ISNULL(@parXML.value('(/row/@cKmEf2)[1]', 'float'), ''), 
	@cKmEf3=ISNULL(@parXML.value('(/row/@cKmEf3)[1]', 'float'), ''),
	@CO=ISNULL(@parXML.value('(/row/@co)[1]', 'decimal(20,2)'), '0'),
	@cRezervor=ISNULL(@parXML.value('(/row/@cRezervor)[1]', 'float'), ''), 
	@update=ISNULL(@parXML.value('(/row/@update)[1]', 'int'), ''),
	@comanda=ISNULL(@parXML.value('(/row/@comanda)[1]', 'varchar(40)'), ''),
	@lm=ISNULL(@parXML.value('(/row/@lm)[1]', 'varchar(40)'), ''),
	@grupa=ISNULL(@parXML.value('(/row/@grupa)[1]', 'varchar(3)'), ''),
	@o_codMasina=ISNULL(@parXML.value('(/row/@o_codMasina)[1]', 'varchar(20)'), ''),
	@o_grupa=ISNULL(@parXML.value('(/row/@o_grupa)[1]', 'varchar(3)'), ''),
	@tipactivitate=ISNULL(@parXML.value('(/row/@tipactivitate)[1]', 'varchar(20)'), '')

set @tipMasina=(select max(g.tip_masina) from grupemasini g where g.Grupa=@grupa)

select @mesajeroare = isnull(@mesajeroare,'')+ 
(case	when @codMasina='' and @update=1 then 'Cod masina necompletat!' + CHAR(10)
		when @denumire='' then 'Descrirere masina necompletata!' + CHAR(10)
		when @tipMasina='' then 'Tipul masinii nu poate fi determinat!' + CHAR(10)
		when @grupa='' then 'Alegeti grupa masinii!' + CHAR(10)
		else '' 
end)

if @mesajeroare<>''
	raiserror (@mesajeroare,11,1)

/* scriu in tabela masini */
if @update=0 /* masina noua*/
begin
	if isnull(@codMasina,'')='' 
	   set @codMasina = isnull( (select MAX(convert(int,cod_masina)) from masini where ISNUMERIC(cod_masina)=1 ) , 0) + 1
	insert into masini(cod_masina, tip_masina,nr_inmatriculare,denumire,nr_inventar, capacitate_metri_cubi, consum_normat_100km,
		consum_pe_ora, grupa, loc_de_munca,coeficient,tonaj, benzina_sau_motorina, capacitate_rezervor, capacitate_baie_de_ulei,
		norma_de_ulei,consum_vara, consum_iarna, consum_usor, consum_mediu, consum_greu, km_la_bord_efectivi, km_la_bord_echivalenti,
		km_SU, km_RK, km_RT1, km_RT2, ultim_SU, ultim_RK, ultim_RT1, ultim_RT2, de_care_masina, de_putere_mare, Comanda, 
		data_expirarii_ITP, Firma_CASCO, Serie_caroserie)
	values (@codMasina, @tipMasina, left(@codMasina,15), @denumire, @nr_inventar, 0, 0, 
	0, @grupa, @lm, 0, 0, '', 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, '01/01/1901', '01/01/1901', '01/01/1901', '01/01/1901', '', '', @comanda, 
	'01/01/1901', '', '')

end
	else	/* masina existenta */
	begin
		if (@codMasina!=@o_codMasina) 
			raiserror ('Nu este permisa modificarea codului masinii!',16,1)
/*		if (select max(tip_masina) from grupemasini g where g.Grupa=@grupa)<>(select max(tip_masina) from grupemasini g where g.Grupa=@o_grupa)
			raiserror('Nu este permisa schimbarea tipului masinii! Alegeti o grupa din acelasi tip!',16,1)*/
		if exists (select 1 from masini where cod_masina=@codMasina)
				update masini 
					set denumire=@denumire, tip_masina=@tipMasina, cod_masina=@codMasina, nr_inmatriculare=left(@codMasina,15), 
						nr_inventar=@nr_inventar, comanda=@comanda ,loc_de_munca=@lm, grupa=@grupa
				where cod_masina=@codMasina
			else 
			raiserror('Codul masinii nu poate fi gasit!',11,1)				
	end

				
/* scriu valori implementare */
delete from valelemimpl where Masina=@codMasina and element in ('RestDecl', 'KmBord')

insert into valelemimpl (Masina, Element, Valoare) values (@codMasina, 'RestDecl', @RestDeclImpl)
insert into valelemimpl (Masina, Element, Valoare) values (@codMasina, 'KmBord', @KmBordImpl)

/* scriu coeficienti */
delete from coefmasini where Masina=@codMasina and Coeficient in ('C100', 'cIarna', 'cVara', 'cKmEf1', 'cKmEf2', 'cKmEf3', 'cRezervor','CO')
insert into coefmasini (Masina, Coeficient, Valoare, Interval) 
values (@codMasina, 'C100', @C100, 100) 
insert into coefmasini (Masina, Coeficient, Valoare, Interval) 
values (@codMasina, 'cIarna', @cIarna, 0)
insert into coefmasini (Masina, Coeficient, Valoare, Interval) 
values (@codMasina, 'cVara', @cVara, 0)
insert into coefmasini (Masina, Coeficient, Valoare, Interval) 
values (@codMasina, 'cKmEf1', @cKmEf1, 0)
insert into coefmasini (Masina, Coeficient, Valoare, Interval) 
values (@codMasina, 'cKmEf2', @cKmEf2, 0)
insert into coefmasini (Masina, Coeficient, Valoare, Interval) 
values (@codMasina, 'cKmEf3', @cKmEf3, 0)
insert into coefmasini (Masina, Coeficient, Valoare, Interval) 
values (@codMasina, 'cRezervor', @cRezervor, 0)
insert into coefmasini (Masina, Coeficient, Valoare, Interval) 
values (@codMasina, 'CO', @C100, 0)

	/*select tip_activitate from tipmasini 	
		if @tipactivitate='P'
			set @C100= 'C100'
		else if @tipactivitate='L'
			set @CO='CO'	
   */
end try
begin catch
	declare @mesaj varchar(254)
	set @mesaj = '(wScriuMasina:)'+char(10)+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch

end
