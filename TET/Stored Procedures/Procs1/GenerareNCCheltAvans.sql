--***
create procedure GenerareNCCheltAvans @numar varchar(13), @data datetime,
@contavans varchar(40), @nrluni int, @nrpozitie float=0, @sesiune varchar(50)=null
as
begin try
declare @sub varchar(9),@tip varchar(2),@datal datetime,@cant float,@pret float,@lm varchar(9),
	@com varchar(20),@indbug varchar(20),@contstoc varchar(40),
	@eroare varchar(254), @userASiS varchar(10), @input XML

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
set @tip='RS'
select @cant=cantitate, @pret=Pret_de_stoc, @lm=loc_de_munca, @com=LEFT(comanda,20), 
	@indbug=SUBSTRING(comanda,21,20), @contstoc=cont_de_stoc
	from pozdoc where subunitate=@sub and tip=@tip and Numar=@numar and data=@data 
	and Numar_pozitie=@nrpozitie
			
declare cursorptNCcheltavans cursor for
	select distinct Data_lunii
	FROM fCalendar (@data,DATEADD(MONTH,@nrluni-1,@data)) --group by Data_lunii
	ORDER BY data_lunii

open cursorptNCcheltavans
fetch next from cursorptNCcheltavans into @datal
while @@fetch_status = 0
begin
	set @input=(select /*Data_lunii*/@datal as '@data', 'NC' as '@tip', @numar as '@numar',
		(select convert(decimal(17,2),(case when @datal=dbo.eom(@data) then 
				round(@cant*@pret,2)-round(@cant*@pret/@nrluni,2)*(@nrluni-1) 
				else round(@cant*@pret/@nrluni,2) end)) as '@suma',
                @com as '@comanda', @lm as '@lm', @indbug as '@indbug',
                @contstoc as '@cont_debitor', @contavans as '@cont_creditor', 
                'CHELTUIELI IN AVANS' as '@ex'
            for XML path,type)
        --from fCalendar (@data,DATEADD(MONTH,@nrluni-1,@data)) group by Data_lunii
		for xml path,type)
	--select @input
	--set @sesiune=(select MAX(token) from ASiSRIA..sesiuniRIA)
	exec wScriuPozNcon @sesiune,@input
		
	fetch next from cursorptNCcheltavans into @datal
end
close cursorptNCcheltavans 
deallocate cursorptNCcheltavans 
end try
 
begin catch  
	set @eroare='GenerareNCCheltAvans: '+rtrim(ERROR_MESSAGE())
	raiserror(@eroare, 11, 1) 		
end catch

if isnull(@eroare,'')='' 
begin
	update pozdoc set Cont_de_stoc=@contavans, stare=2/*, locatie=rtrim(str(@nrluni,5))*/
		where subunitate=@sub and tip=@tip and Numar=@numar and data=@data and Numar_pozitie=@nrpozitie
	update ncon set stare=2
		where subunitate=@sub and tip='NC' and Numar=@numar and data between dbo.eom(@data) 
		and DATEADD(MONTH,@nrluni-1,dbo.eom(@data))
end
