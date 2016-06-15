--***
create procedure inreg_rec_diferente @cSub char(9), @cTip char(2), @cNumar varchar(20), @dData datetime, @cJurnal char(3)
as
--Declare @cSub char(9), @cTip char(2), @cNumar varchar(20), @dData datetime, @cJurnal char(3)
--Set @cSub = '1'
--Set @cTip = 'RM'
--Set @cNumar = '118'
--Set @dData = '2008/06/30'
--Set @cJurnal = ''
--Lucian 25.06.2013: grupare date in cursor pe loc de munca si comanda pentru a putea scrie in pozincon cele 2 elemente.
Declare @cContPlus varchar(40), @cContMinus varchar(40), @nValMin float, @ctVenCh varchar(40), @ctDeb varchar(40) ,@ctCred varchar(40), @nr_pozitie int, @CtAdaos varchar(40), @CtTVAnx varchar(40)

exec luare_date_par 'GE', 'GENDIFRM', 1, @nValMin output,''
exec luare_date_par 'GE', 'RMCTDIFP', 1, 1,@cContPlus output
exec luare_date_par 'GE', 'RMCTDIFN', 1, 1,@cContMinus output
exec luare_date_par 'GE', 'CADAOS', 0, 0, @CtAdaos output
exec luare_date_par 'GE', 'CNTVA', 0, 0, @CtTVAnx output

Declare @ctStoc varchar(40), @lm varchar(9), @comanda varchar(20), @nValDoc float, @nValInreg float, @nValDif float

Declare crPozitii cursor for
select p.cont_de_stoc, p.Loc_de_munca, p.comanda, sum(round(convert(decimal(17,5), p.cantitate*p.pret_de_stoc), 2)) as val 
from pozdoc p 
	inner join conturi c on p.subunitate = c.subunitate and p.cont_de_stoc = c.cont
where p.subunitate = @cSub and p.tip = @cTip and p.numar = @cNumar and p.data = @dData and c.sold_credit = 3
group by p.cont_de_stoc, p.comanda, p.Loc_de_munca

Open crPozitii
Fetch next from crPozitii into @ctStoc, @lm, @comanda, @nValDoc
While @@fetch_status = 0
Begin
	Set @nValInreg = (select sum(round(convert(decimal(17,5), suma), 2)) from pozincon where subunitate = @cSub and tip_document = @cTip 
		and numar_document = @cNumar and data = @dData and cont_debitor = @ctStoc and Loc_de_munca=@lm and Comanda=@comanda
		and (@CtAdaos='' or cont_creditor not like RTrim(@CtAdaos)+'%') 
		and (@CtTVAnx='' or cont_creditor not like RTrim(@CtTVAnx)+'%')) 
	Set @nValDif = @nValDoc - @nValInreg
	if abs(@nValDif) >= @nValMin
	begin
		if @nValDif < 0
		begin
			Set @ctDeb = @ctStoc
			Set @ctCred = @cContMinus
		end
		else 
		begin
			Set @ctDeb = @cContPlus
			Set @ctCred = @ctStoc
			set @nValDif=-@nValDif
		end
		Set @nr_pozitie = isnull((select max(numar_pozitie) from pozincon where subunitate = @cSub and tip_document = @cTip 
			and numar_document = @cNumar and data = @dData),0)+1
		exec scriuPozincon @cSub,@cTip,@cNumar,@dData,@ctDeb,@ctCred,@nValDif,'',0,0,'CORECTIE','',@nr_pozitie,@lm,@comanda,@cJurnal,0
	end
	Fetch next from crPozitii into @ctStoc, @lm, @comanda, @nValDoc
End
Close crPozitii
Deallocate crPozitii
