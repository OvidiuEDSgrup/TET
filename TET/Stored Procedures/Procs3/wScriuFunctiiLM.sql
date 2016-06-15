/** procedura de scriere pe functiilor pe locuri de munca **/
Create procedure wScriuFunctiiLM @sesiune varchar(30), @parXML XML
as
declare @update bit, @lm varchar(9), @data datetime, @functie varchar(6), @denpost varchar(50), @tippersonal char(1), @salarincadrare decimal(10), 
	@nrposturi float, @regimlucru float, @pozitiestat int

Select @update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
       @lm = upper(isnull(@parXML.value('(/row/@lm)[1]','varchar(9)'),'')),
       @data= @parXML.value('(/row/row/@data)[1]','datetime'),
       @functie = upper(@parXML.value('(/row/row/@functie)[1]','varchar(6)')),
       @denpost = upper(isnull(@parXML.value('(/row/row/@denpost)[1]','varchar(50)'),'')),
       @tippersonal = upper(@parXML.value('(/row/row/@tippersonal)[1]','varchar(1)')),
       @salarincadrare = isnull(@parXML.value('(/row/row/@salarincadrare)[1]','decimal(10)'),0),
       @nrposturi = @parXML.value('(/row/row/@nrposturi)[1]','decimal(10)'),
       @regimlucru = isnull(@parXML.value('(/row/row/@regimlucru)[1]','float'),0),
       @pozitiestat = @parXML.value('(/row/row/@pozitiestat)[1]','int')

begin try
	if @update=1
	begin
		declare @o_functie varchar(6), @o_data datetime
		Select @o_functie= @parXML.value('(/row/row/@o_functie)[1]','varchar(6)'),
			@o_data= isnull(@parXML.value('(/row/row/@o_data)[1]','datetime'),'1900-01-01')

		update functii_lm set Data=@data, Cod_functie=@functie, Denumire=@denpost, Tip_personal=@tippersonal, 
			Salar_de_incadrare=@salarincadrare, Numar_posturi=@nrposturi, Regim_de_lucru=@regimlucru, Pozitie_stat=@pozitiestat
		where Data=@o_data and Loc_de_munca=@lm and Cod_functie=@o_functie
	end
	else
		insert into functii_lm(Data, Loc_de_munca, Cod_functie, Denumire, Tip_personal, Salar_de_incadrare, Numar_posturi, Regim_de_lucru, Pozitie_stat)
			values(@data, @lm, @functie, @denpost, @tippersonal, @salarincadrare, @nrposturi, @regimlucru, @pozitiestat)
end try

begin catch
	declare @mesaj varchar(254)
	set @mesaj = '(wScriuFunctiiLM) '+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
