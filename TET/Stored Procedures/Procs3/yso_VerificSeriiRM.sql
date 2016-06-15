CREATE PROCEDURE yso_VerificSeriiRM @sub char(9),@tip char(2),@numar char(8),@data datetime as
DECLARE	@mesaj varchar(200),@cod char(20),@codintrare char(13),@gestiune char(9),@ContStoc char(13),@PretStoc float,@NrPozitii int  

select TOP 1 @cod=p.cod,@codintrare=P.Cod_intrare
from pozdoc p inner join doc d on d.Subunitate=p.Subunitate and d.Tip=p.Tip and d.Numar=p.Numar and d.Data=p.Data 
 inner join proprietati pr on pr.Tip='NOMENCL' and pr.Cod_proprietate='ARESERII' and pr.Cod=p.Cod and pr.Valoare='DA' and pr.Valoare_tupla=''
where p.Subunitate=@sub and p.Tip=@tip and p.Numar=@numar and p.Data=@data 
	and p.Cod_intrare LIKE RTRIM(LEFT(dbo.formezCodIntrare(p.tip,p.Numar,p.Data,p.cod,p.gestiune,p.Cont_de_stoc,p.Pret_de_stoc),3))+'%'

--select @NrPozitii=d.Numar_pozitii
--from doc d where d.Subunitate=@sub and d.Tip=@tip and d.Numar=@numar and d.Data=@data

set @mesaj='Atentie! Aveti coduri la care nu ati completat seria: '+RTRIM(@cod)+', '+RTRIM(@codintrare)

IF @mesaj is not null
begin
	rollback transaction
	raiserror (@mesaj,11,1)
end