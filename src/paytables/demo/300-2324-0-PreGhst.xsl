<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
				<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					var bonusTotal = 0; 
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						var scenario = getScenario(jsonContext);
						var winningNums = getWinningNumbers(scenario);
						var outcomeNums = getOutcomeData(scenario, 0);
						var outcomePrizes = getOutcomeData(scenario, 1);
						var outcomeTokens = getOutcomeData(scenario, 2);
						var prizeNames = (prizeNamesDesc.substring(1)).split(',');
						var convertedPrizeValues = (prizeValues.substring(1)).split('|');
						var mainJackpotCount = 0;
						var bonusTriggerCount = 0;
						var bonusPlayed = false;

						///////////////////////
						// Output Game Parts //
						///////////////////////
						const cellHeight    = 48;
						//const cellWidth     = 80;
						const cellMargin    = 1;
						const cellSizeX     = 80;
						const cellSizeY     = 48;
						const cellTextX     = 40; 
						const cellTextY     = 12; 
						const cellTextY1    = 27; 
						const cellTextY2    = 42; 
						const cellTextYB1   = 18; 
						const cellTextYB2   = 36; 
						const colourBlack   = '#000000';
						const colourBlue 	= '#89cff0';
						const colourLime    = '#ccff99';
						const colourRed     = '#ff9999';
						const colourWhite   = '#ffffff';
						const colourYellow	= '#ffff00';

						var boxColourStr  = '';
						var textColourStr = '';
						var canvasIdStr   = '';
						var elementStr    = '';

						const gridCols 		= 5;
						const gridRows 		= 4;
						const arrMGMultVals = [1,2,3,4,5,6,7];
						const arrMGMultWins = ["1","2","3","5","10","20","50"];
						const arrMGMultTokens = ["N","B","J"];
						const arrMGMultTexts = ["","bonusPlus","jackpotPlus"];
						const arrBGMultVals = [1,2,3];
						const arrBGMultWins = ["1","2","3"];
						
						var r = [];

						///// Test /////
					//	r.push("<p>" + winningNums + "</p>");
					//	r.push("<p>" + outcomeNums + "</p>");
					//	r.push("<p>" + outcomePrizes + "</p>");
					//	r.push("<p>" + outcomeTokens + "</p>");
						///// Test /////

						/////////////////////////
						// Data pre-processing //
						/////////////////////////
						for (var i = 0; i < outcomeTokens.length; i++)
						{
							if (outcomeTokens[i] == arrMGMultTokens[1]) // Bonus
							{
								bonusTriggerCount++;
							}
							else if (outcomeTokens[i] == arrMGMultTokens[2]) // Jackpot
							{
								mainJackpotCount++;
							}
						}

						var gridCanvasWinsHeight = cellSizeY + 2 * cellMargin;
						var gridCanvasWinsWidth  = (gridCols+1) * cellSizeX + 2 * cellMargin;
						var gridCanvasYourHeight = gridRows * cellSizeY + 2 * cellMargin;
						var gridCanvasYourWidth  = gridCols * cellSizeX + 2 * cellMargin;

						function showWinningNums(A_strCanvasId, A_strCanvasElement, A_strBoxColour, A_strTextColour, A_strText)
						{
							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
							var canvasWidth  = cellSizeX + 2 * cellMargin;
							var canvasHeight = cellSizeY + 2 * cellMargin;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + canvasWidth.toString() + '" height="' + canvasHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold 14px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');

							r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellMargin + 0.5).toString() + ', ' + cellSizeX.toString() + ', ' + cellSizeY.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellMargin + 1.5).toString() + ', ' + (cellSizeX - 2).toString() + ', ' + (cellSizeY - 2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strTextColour + '";');
							r.push(canvasCtxStr + '.fillText("' + A_strText + '", ' + (cellSizeX / 2 + cellMargin).toString() + ', ' + (cellSizeY / 2 + cellMargin).toString() + ');');

							r.push('</script>');
						}

						function showYourNums(A_strCanvasId, A_strCanvasElement, A_arrGrid, A_arrPrizes, A_arrTokens)
						{
							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
							var cellX        = 0;
							var cellY        = 0;
							var prizeCell    = '';
							var prizeStr	 = '';
							var symbCell     = '';
							var tokenCell    = '';
							var tokenStr 	 = '';
							var tempNum		 = -1;
							var boolWinCell  = false;
							var boolInstWinCell  = false;
						
							r.push('<canvas id="' + A_strCanvasId + '" width="' + gridCanvasYourWidth.toString() + '" height="' + gridCanvasYourHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');

							var gridRow = -1;
							for (var gridCol = 0; gridCol < A_arrGrid.length; gridCol++)
							{
								if ((gridCol % gridCols) == 0)
								{
									gridRow++;
								}
								symbCell = A_arrGrid[gridCol];
								prizeCell = convertedPrizeValues[getPrizeNameIndex(prizeNames, A_arrPrizes[gridCol])];
								tokenStr = A_arrTokens[gridCol];

								boolWinCell = (winningNums.indexOf(symbCell) > -1);

								boolInstWinCell = (symbCell[0] == '-');
								if (!boolInstWinCell)
								{
									boolWinCell = (winningNums.indexOf(symbCell) > -1);
								}

								symbCell = boolInstWinCell ? getTranslationByName("instantWin", translations) + ' x' + arrMGMultWins[arrMGMultVals.indexOf(parseInt(symbCell.slice(1)))] : symbCell;
								tokenCell = (arrMGMultTexts[arrMGMultTokens.indexOf(tokenStr)]).length > 0 ? getTranslationByName(arrMGMultTexts[arrMGMultTokens.indexOf(tokenStr)], translations) + ' +1' : "";

								boxColourStr  = (boolWinCell)||(boolInstWinCell) ? colourYellow : ((tokenStr == arrMGMultTokens[2]) && (mainJackpotCount == 5) ? colourLime : ((tokenStr == arrMGMultTokens[1]) && (bonusTriggerCount == 3) ? colourBlue : colourWhite));
								textColourStr = colourBlack; 
								cellX         = (gridCol % gridCols) * cellSizeX;
								cellY         = gridRow * cellSizeY;

								r.push(canvasCtxStr + '.strokeRect(' + (cellX + cellMargin + 0.5).toString() + ', ' + (cellY + cellMargin + 0.5).toString() + ', ' + cellSizeX.toString() + ', ' + cellSizeY.toString() + ');');
								r.push(canvasCtxStr + '.fillStyle = "' + boxColourStr + '";');
								r.push(canvasCtxStr + '.fillRect(' + (cellX + cellMargin + 1.5).toString() + ', ' + (cellY + cellMargin + 1.5).toString() + ', ' + (cellSizeX - 2).toString() + ', ' + (cellSizeY - 2).toString() + ');');
								r.push(canvasCtxStr + '.fillStyle = "' + textColourStr + '";');
								r.push(canvasCtxStr + '.font = "bold 12px Arial";');
								r.push(canvasCtxStr + '.fillText("' + symbCell + '", ' + (cellX + cellTextX).toString() + ', ' + (cellY + cellTextY).toString() + ');');
								r.push(canvasCtxStr + '.fillText("' + prizeCell + '", ' + (cellX + cellTextX).toString() + ', ' + (cellY + cellTextY1).toString() + ');');
								r.push(canvasCtxStr + '.fillText("' + tokenCell + '", ' + (cellX + cellTextX).toString() + ', ' + (cellY + cellTextY2).toString() + ');');
							}
							r.push('</script>');
						}

						function showBonusGame(A_strCanvasId, A_strCanvasElement, A_arrBonusGame, A_boolBonusJackpotWin)
						{
							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
							var cellX        = 0;
							var cellY        = 0;
							var prizeCell    = '';
							var prizeStr	 = '';
							var symbCell     = '';
							var tempNum		 = -1;
							var boolWinCell  = false;
						
							r.push('<canvas id="' + A_strCanvasId + '" width="' + gridCanvasYourWidth.toString() + '" height="' + gridCanvasYourHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');

							var gridRow = -1;
							for (var gridCol = 0; gridCol < A_arrBonusGame.length; gridCol++)
							{
								if ((gridCol % gridCols) == 0)
								{
									gridRow++;
								}
								symbCell = A_arrBonusGame[gridCol].bonusItem;
								prizeCell = '';
								if (symbCell != arrMGMultTokens[2])
								{
									prizeCell = convertedPrizeValues[getPrizeNameIndex(prizeNames, A_arrBonusGame[gridCol].bonusPrize)];
								}

								boolWinCell = (arrBGMultVals.indexOf(parseInt(symbCell)) > -1);

								symbCell = boolWinCell ?  'x' + arrBGMultWins[arrBGMultVals.indexOf(parseInt(symbCell))] : ((symbCell == arrMGMultTokens[2]) ? getTranslationByName("jackpot", translations) : symbCell);

								boolWinCell = (A_boolBonusJackpotWin && (A_arrBonusGame[gridCol].bonusItem == arrMGMultTokens[2])) ? true : boolWinCell;

								boxColourStr  = (boolWinCell) ? colourLime : colourWhite;
								textColourStr = colourBlack; 
								cellX         = (gridCol % gridCols) * cellSizeX;
								cellY         = gridRow * cellSizeY;

								r.push(canvasCtxStr + '.strokeRect(' + (cellX + cellMargin + 0.5).toString() + ', ' + (cellY + cellMargin + 0.5).toString() + ', ' + cellSizeX.toString() + ', ' + cellSizeY.toString() + ');');
								r.push(canvasCtxStr + '.fillStyle = "' + boxColourStr + '";');
								r.push(canvasCtxStr + '.fillRect(' + (cellX + cellMargin + 1.5).toString() + ', ' + (cellY + cellMargin + 1.5).toString() + ', ' + (cellSizeX - 2).toString() + ', ' + (cellSizeY - 2).toString() + ');');
								r.push(canvasCtxStr + '.fillStyle = "' + textColourStr + '";');
								r.push(canvasCtxStr + '.font = "bold 12px Arial";');
								r.push(canvasCtxStr + '.fillText("' + symbCell + '", ' + (cellX + cellTextX).toString() + ', ' + (cellY + cellTextYB1).toString() + ');');
								r.push(canvasCtxStr + '.fillText("' + prizeCell + '", ' + (cellX + cellTextX).toString() + ', ' + (cellY + cellTextYB2).toString() + ');');
							}
							r.push('</script>');
						}

						// Output winning numbers table.
						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
 						r.push('<tr><td class="tablehead" colspan="' + winningNums.length + '">');
 						r.push(getTranslationByName("winningNumbers", translations));
 						r.push('</td></tr>');
 						r.push('<tr>');
						for (var i = 0; i < winningNums.length; i++)
						{
							canvasIdStr = 'cvsWinningGrid0' + i; 
							elementStr  = 'eleWinningGrid0' + i; 

							symbCell = winningNums[i];
							boolWinCell = (outcomeNums.indexOf(symbCell) > -1);

							boxColourStr  = (boolWinCell == true) ? colourYellow : colourWhite;
							textColourStr = colourBlack; 
							cellX         = i * cellSizeX;
							cellY         = 0;
					
							r.push('<td>');
							showWinningNums(canvasIdStr, elementStr, boxColourStr, textColourStr, symbCell);
							r.push('</td>');
						}
						r.push('</tr>');
 						r.push('</table>');

						/////////////////
						// Your Groups //
						/////////////////
						canvasIdStr = 'cvsYourGrid0'; 
						elementStr  = 'eleYourGrid0'; 

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr>');
						r.push('<td>' + getTranslationByName("yourNumbers", translations) + '</td>');
						r.push('</tr>');
						r.push('<tr>');
						r.push('<td align="center">');
						showYourNums(canvasIdStr, elementStr, outcomeNums, outcomePrizes, outcomeTokens);
						r.push('</td>');
						r.push('</tr>');
						r.push('</table>');
						r.push('</br>');

						if (bonusTriggerCount == 3)
						{
							bonusPlayed = true;
						}

						// Bonus keys information
					//	var bonusPrizeValue = ""; 
					//	r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
					//	r.push('<tr>');
 					//	r.push('<td class="tablehead">');
 					//	r.push(getTranslationByName("bonusTotal", translations));
 					//	r.push('</td>');
					//	r.push('<td class="tablehead">');
 					//	r.push(getTranslationByName("bonusPrize", translations));
 					//	r.push('</td>');
					//	r.push('</tr>');
					//	r.push('<tr>');
					//	r.push('<td>');
					//	r.push(bonusPrizeValue);
					//	r.push('</td>');
					//	r.push('</tr>');
					//	r.push('</table>');
					//	r.push('</br>');

						if (bonusPlayed)
						{
							var bonusData = getBonusValues(scenario);
							var bonusJackpotCount = 0;
							for(var i = 0; i < bonusData.length; i++)
							{
								if (bonusData[i].bonusItem == arrMGMultTokens[2])
								{
									bonusJackpotCount++;
								}
							}

							var bonusJackpotWin = (bonusJackpotCount == 5) ? true : false;

							canvasIdStr = 'cvsBonus0'; 
							elementStr  = 'eleBonus0'; 

							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
							r.push('<tr>');
							r.push('<td>' + getTranslationByName("bonusGame", translations) + '</td>');
							r.push('</tr>');
							r.push('<tr>');
							r.push('<td align="center">');
							showBonusGame(canvasIdStr, elementStr, bonusData, bonusJackpotWin);
							r.push('</td>');
							r.push('</tr>');
							r.push('</table>');
							r.push('</br>');
						}

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
	 						{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 								r.push('</td>');
 								r.push('</tr>');
							}
							r.push('</table>');
						}
						return r.join('');
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");

						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}
						return "";
					}

					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');
						return scenario;
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;
						return pricePoint;
					}

					// Input: "23,9,31|8:E,35:E,4:D,13:D,37:G,..."
					// Output: ["23", "9", "31"]
					function getWinningNumbers(scenario)
					{
						var numsData = scenario.split("|")[0];
						return numsData.split(",");
					}

					function getBonusValues(scenario)
					{
						var objItem    = {};
						var numsData   = [];
						var itemData   = [];
						var outcomeData = scenario.split("|")[2];
						var outcomePairs = outcomeData.split(",");
						for(var i = 0; i < outcomePairs.length; ++i)
						{
							itemData = outcomePairs[i].split(":");
							objItem = {bonusItem: itemData[0], bonusPrize: itemData[1]};
							numsData.push(objItem);
						}
						return numsData;
					}

					// Input: "23,9,31|8:m8:N,35:m10:N,4:m1:N,13:m4:B,37:m12:N,..."
					// Output: ["8", "35", "4", "13", ...] , ["m8", "m10", "m1", "m4", "m12" ...] or ["N", "N", "N", "B", "N",]
					function getOutcomeData(scenario, index)
					{
						var outcomeData = scenario.split("|")[1];
						var outcomePairs = outcomeData.split(",");
						var result = [];
						var temp = '';

						for(var i = 0; i < outcomePairs.length; ++i)
						{
							temp = outcomePairs[i].split(":")[index];
							result.push(temp);
						}
						return result;
					}

					// Input: 'X', 'E', or number (e.g. '23')
					// Output: translated text or number.
					function translateOutcomeNumber(outcomeNum, translations)
					{
						if (outcomeNum == "T")
						{
							return getTranslationByName("bonusVaultTrigger", translations);
						}
						else if (outcomeNum == "V")
						{
							return ("");
						}
						else if (outcomeNum == "W")
						{
							return ("2x");
						}
						else if (outcomeNum == "X")
						{
							return ("5x");
						}
						else if (outcomeNum == "Y")
						{
							return ("10x");
						}
						else
						{
							return outcomeNum;
						}
					}

					// Input: List of winning numbers and the number to check
					// Output: true is number is contained within winning numbers or false if not
					function checkMatch(winningNums, boardNum)
					{
						for(var i = 0; i < winningNums.length; ++i)
						{
							if(winningNums[i] == boardNum)
							{
								return true;
							}
						}
						return false;
					}

					// Input: number to check
					// Output: true if number is instant win or false if not
					function instantWin(boardNum)
					{
						if(boardNum == "V" || boardNum == "W" || boardNum == "X" || boardNum == "Y")
						{
							return true;
						}
						return false;
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
				]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="SignedData/Data/Outcome/ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			

				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>				
				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
						<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
