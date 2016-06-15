/* 
procedura folosita pentru a citi setari de PV de pe server.
Pentru inceput se citeste doar setarea de ping server daca nu se lucreaza cu aplicatia, 
dar in viitor vom trimite setarile aplicatiei PV de pe server. */
create procedure wIaSetariPV @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wIaSetariPVSP' and type='P')      
begin
	exec wIaSetariPVSP @sesiune,@parXML      
	return 
end

set transaction isolation level read uncommitted

declare @ping INT, @descarcarePrioritara bit, @bonCuFormular bit,
		@fidelizare bit, @idIncasareCard bit, @nivelProcesarePeServer int, @incasariPeFacturi INT, @cereDetaliiBon bit,
		@cuKeypad bit, @tileH int, @tileW int, @arePoza int, @tFont int, @tFontBold int,
		@nuAnulezBon bit
		--, @textButonConfigurabil varchar(50), @codIncasareConfigurabila int
		
SELECT	@ping=0, @descarcarePrioritara=0, @bonCuFormular=0, @fidelizare=0, @idIncasareCard=0, @nivelProcesarePeServer=0, 
		@incasariPeFacturi=0

SELECT	@ping = (CASE WHEN Parametru='PING' THEN Val_numerica ELSE @ping end),
		@descarcarePrioritara = (CASE WHEN Parametru='DESCPRIOR' THEN Val_logica ELSE @descarcarePrioritara end),
		@bonCuFormular = (CASE WHEN Parametru='BONCUFORM' THEN Val_logica ELSE @bonCuFormular end),
		@fidelizare = (CASE WHEN Parametru='FIDELIZ' THEN Val_logica ELSE @fidelizare end),
		@idIncasareCard = (CASE WHEN Parametru='IDINCCARD' THEN Val_logica ELSE @idIncasareCard end),
		@nivelProcesarePeServer = (CASE WHEN Parametru='PROCESARE' THEN Val_numerica ELSE @nivelProcesarePeServer end),
		@incasariPeFacturi = (CASE WHEN Parametru='INCPEFACT' THEN Val_numerica ELSE @incasariPeFacturi end),
		@cereDetaliiBon = (CASE WHEN Parametru='CERDETBON' THEN Val_logica ELSE @cereDetaliiBon end),
		@cuKeypad = (CASE WHEN Parametru='CUKEYPAD' THEN Val_logica ELSE @cuKeypad end),
		@tileH = (CASE WHEN Parametru='TILEH' THEN Val_numerica ELSE @tileH end), 
		@tileW = (CASE WHEN Parametru='TILEW' THEN Val_numerica ELSE @tileW end),
		@tFont = (CASE WHEN Parametru='TFONT' THEN Val_numerica ELSE @tFont end),
		@tFontBold = (CASE WHEN Parametru='TFONTBOLD' THEN Val_logica ELSE @tFontBold end),
		@nuAnulezBon = (CASE WHEN Parametru='NUANULEZB' THEN Val_logica ELSE @nuAnulezBon end)
-- select *
FROM par
WHERE Tip_parametru='PV' 
	AND Parametru IN ('PING', 'DESCPRIOR', 'BONCUFORM', 'FIDELIZ', 'IDINCCARD', 'PROCESARE', 'INCPEFACT', 'INCCONF3', 'CERDETBON',
		'CUKEYPAD', 'TILEH', 'TILEW', 'TFONT', 'TFONTBOLD','NUANULEZB')

		

--exec luare_date_par 'PV','INCCONF3',0, @codIncasareConfigurabila output, @textButonConfigurabil output
--exec luare_date_par 'PV','CERDETBON', @cereDetaliiBon output, 0 , '' 

select @ping secundePing, @descarcarePrioritara descarcarePrioritara, @bonCuFormular as bonCuFormular, @fidelizare carduriFidelizare,
	@idIncasareCard idIncasareCard, @nivelProcesarePeServer nivelProcesarePeServer,
	@incasariPeFacturi incasariPeFacturi, @cereDetaliiBon cereDetaliiBon, @cuKeypad cuKeypad,
	@tileH tileHeight, @tileW tileWidth, @tFont tileFontSize, @tFontBold tileFontBold,
	@nuAnulezBon nuAnulezB
for xml raw, root('Date')

--select * from par where tip_parametru='pv'
