declare @p2 xml
set @p2=convert(xml,N'<parametri data="05/30/2014" ora="14:21:01" utilizator="ASIS" id="512605" datainf="07/01/2014" datasup="08/31/2014" RM="1" PP="1" CM="1" AP="1" AC="1" AS="1" TE="1" DF="1" PF="1" CI="1" AF="1" AI="1" AE="1" PI="1" AD="1" NC="1" o_datainf="06/01/2014" o_datasup="06/30/2014" o_RM="1" o_PP="1" o_CM="1" o_AP="1" o_AS="1" o_AC="1" o_TE="1" o_DF="1" o_PF="1" o_CI="1" o_AF="1" o_AI="1" o_AE="1" o_PI="1" o_AD="1" o_NC="1" update="1" tip="YJ" tipMacheta="O" codMeniu="YJ" TipDetaliere="YJ" subtip="YJ" nrdoc="" o_nrdoc=""/>')
exec wOPRefacereInregistrariContabile @sesiune='',@parXML=@p2

select *
from pozdoc 
where tip='AP' and data between '07/01/2014' and '08/31/2014' 
	and gestiune_primitoare not like '378%'  and gestiune_primitoare<>'' and Cont_intermediar=''
order by idPozDoc desc

