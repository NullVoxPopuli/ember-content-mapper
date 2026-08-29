## Text

```ts
/// <reference types="ember-source/types" />
/// <reference types="@glint/ember-tsc/types" />
import { concat, uniqueId } from '@ember/helper';

import Component from '@glimmer/component';

export default class Foo extends Component {
	static { ({} as typeof import("@glint/ember-tsc/-private/dsl")).templateForBackingValue(this, function(__glintRef__, __glintDSL__: typeof import("@glint/ember-tsc/-private/dsl")) {
{
const __glintY__ = __glintDSL__.emitComponent(__glintDSL__.resolve(__glintDSL__.Globals.let)(__glintDSL__.resolve(concat)("team-permissions-", __glintDSL__.resolve(uniqueId)())));
{
const [groupId] = __glintY__.blockParams["default"];
{
__glintDSL__.noop(__glintDSL__.elementTypes.div);
__glintDSL__.noop(__glintDSL__.elementTypes["div"]);
const __glintY__ = __glintDSL__.emitElement("div");
__glintDSL__.applySplattributes(__glintRef__.element, __glintY__.element);
__glintDSL__.applyTagAttributes(__glintY__, {
"aria-labelledby": __glintDSL__.resolveOrReturn(groupId)(),
});
{
__glintDSL__.noop(__glintDSL__.elementTypes.div);
__glintDSL__.noop(__glintDSL__.elementTypes["div"]);
const __glintY__ = __glintDSL__.emitElement("div");
{
__glintDSL__.noop(__glintDSL__.elementTypes.div);
__glintDSL__.noop(__glintDSL__.elementTypes["div"]);
const __glintY__ = __glintDSL__.emitElement("div");
__glintDSL__.applyTagAttributes(__glintY__, {
id: __glintDSL__.resolveOrReturn(groupId)(),
});
}
if (!(__glintRef__.args.isReadOnly)) {
}
}
{
__glintDSL__.noop(__glintDSL__.elementTypes.div);
__glintDSL__.noop(__glintDSL__.elementTypes["div"]);
const __glintY__ = __glintDSL__.emitElement("div");
{
__glintDSL__.noop(__glintDSL__.elementTypes.div);
__glintDSL__.noop(__glintDSL__.elementTypes["div"]);
const __glintY__ = __glintDSL__.emitElement("div");
{
const __glintY__ = __glintDSL__.emitComponent(__glintDSL__.resolve(__glintDSL__.Globals.each)(__glintRef__.args.items));
{
const [allowedTeam] = __glintY__.blockParams["default"];
{
__glintDSL__.noop(__glintDSL__.elementTypes.div);
__glintDSL__.noop(__glintDSL__.elementTypes["div"]);
const __glintY__ = __glintDSL__.emitElement("div");
{
__glintDSL__.noop(__glintDSL__.elementTypes.div);
__glintDSL__.noop(__glintDSL__.elementTypes["div"]);
const __glintY__ = __glintDSL__.emitElement("div");
{
__glintDSL__.noop(__glintDSL__.elementTypes.div);
__glintDSL__.noop(__glintDSL__.elementTypes["div"]);
const __glintY__ = __glintDSL__.emitElement("div");
__glintDSL__.applyTagAttributes(__glintY__, {
"data-x": __glintDSL__.resolveOrReturn(allowedTeam?.id)(),
});
}
if (!(__glintRef__.args.isReadOnly)) {
}
}
}
if (__glintRef__.args.isReadOnly) {
}
}
__glintDSL__.Globals.each;
}
}
}
}
}
__glintDSL__.Globals.let;
}
__glintRef__; __glintDSL__;
}) }
}

```

## Mappings

- verbatim [94, 236) -> [0, 142) features=all "import { concat, uniqueId } from '@ember/helper';\n\nimport Component from '@gl…
- atom [236, 266) -> [142, 142) features=0 "static { ({} as typeof import(" <- ""
- atom [266, 297) -> [152, 152) features=727039 "\"@glint/ember-tsc/-private/dsl\"" <- ""
- atom [297, 417) -> [142, 142) features=0 ")).templateForBackingValue(this, function(__glintRef__, __glintDSL__: typeof im… <- ""
- atom [417, 425) -> [155, 155) features=0 "{\nconst " <- ""
- atom [435, 465) -> [155, 155) features=0 " = __glintDSL__.emitComponent(" <- ""
- atom [465, 486) -> [158, 161) features=0 "__glintDSL__.resolve(" <- "let"
- atom [486, 507) -> [158, 161) features=0 "__glintDSL__.Globals." <- "let"
- verbatim [507, 510) -> [158, 161) features=727039 "let"
- atom [510, 511) -> [158, 161) features=0 ")" <- "let"
- atom [511, 512) -> [155, 155) features=0 "(" <- ""
- atom [512, 533) -> [163, 169) features=0 "__glintDSL__.resolve(" <- "concat"
- verbatim [533, 539) -> [163, 169) features=727039 "concat"
- atom [539, 540) -> [163, 169) features=0 ")" <- "concat"
- atom [540, 541) -> [162, 162) features=0 "(" <- ""
- verbatim [541, 560) -> [170, 189) features=727039 "\"team-permissions-\""
- atom [560, 562) -> [162, 162) features=0 ", " <- ""
- atom [562, 583) -> [191, 199) features=0 "__glintDSL__.resolve(" <- "uniqueId"
- verbatim [583, 591) -> [191, 199) features=727039 "uniqueId"
- atom [591, 592) -> [191, 199) features=0 ")" <- "uniqueId"
- atom [592, 594) -> [190, 190) features=0 "()" <- ""
- atom [594, 595) -> [162, 162) features=0 ")" <- ""
- atom [595, 596) -> [155, 155) features=0 ")" <- ""
- atom [596, 608) -> [155, 155) features=0 ");\n{\nconst [" <- ""
- atom [615, 654) -> [155, 155) features=0 "] = __glintY__.blockParams[\"default\"];\n" <- ""
- atom [654, 700) -> [220, 220) features=0 "{\n__glintDSL__.noop(__glintDSL__.elementTypes." <- ""
- verbatim [700, 703) -> [221, 224) features=529411 "div"
- atom [703, 751) -> [220, 220) features=0 ");\n__glintDSL__.noop(__glintDSL__.elementTypes[\"" <- ""
- verbatim [751, 754) -> [221, 224) features=66552 "div"
- atom [754, 765) -> [220, 220) features=0 "\"]);\nconst " <- ""
- atom [775, 811) -> [220, 220) features=0 " = __glintDSL__.emitElement(\"div\");\n" <- ""
- atom [811, 843) -> [253, 266) features=0 "__glintDSL__.applySplattributes(" <- "...attributes"
- atom [843, 863) -> [253, 266) features=727039 "__glintRef__.element" <- "...attributes"
- atom [863, 865) -> [253, 266) features=0 ", " <- "...attributes"
- atom [865, 883) -> [253, 266) features=727039 "__glintY__.element" <- "...attributes"
- atom [883, 885) -> [253, 266) features=0 ");" <- "...attributes"
- atom [885, 886) -> [220, 220) features=0 "\n" <- ""
- atom [886, 918) -> [224, 224) features=0 "__glintDSL__.applyTagAttributes(" <- ""
- atom [918, 928) -> [225, 225) features=0 "__glintY__" <- ""
- atom [928, 932) -> [224, 224) features=0 ", {\n" <- ""
- atom [932, 933) -> [225, 225) features=0 "\"" <- ""
- verbatim [933, 948) -> [225, 240) features=727039 "aria-labelledby"
- atom [948, 951) -> [225, 225) features=0 "\": " <- ""
- atom [951, 980) -> [243, 250) features=0 "__glintDSL__.resolveOrReturn(" <- "groupId"
- verbatim [980, 987) -> [243, 250) features=727039 "groupId"
- atom [987, 988) -> [243, 250) features=0 ")" <- "groupId"
- atom [988, 990) -> [241, 241) features=0 "()" <- ""
- atom [990, 992) -> [225, 225) features=0 ",\n" <- ""
- atom [992, 996) -> [224, 224) features=0 "});\n" <- ""
- atom [996, 1042) -> [272, 272) features=0 "{\n__glintDSL__.noop(__glintDSL__.elementTypes." <- ""
- verbatim [1042, 1045) -> [273, 276) features=529411 "div"
- atom [1045, 1093) -> [272, 272) features=0 ");\n__glintDSL__.noop(__glintDSL__.elementTypes[\"" <- ""
- verbatim [1093, 1096) -> [273, 276) features=66552 "div"
- atom [1096, 1107) -> [272, 272) features=0 "\"]);\nconst " <- ""
- atom [1117, 1153) -> [272, 272) features=0 " = __glintDSL__.emitElement(\"div\");\n" <- ""
- atom [1153, 1199) -> [283, 283) features=0 "{\n__glintDSL__.noop(__glintDSL__.elementTypes." <- ""
- verbatim [1199, 1202) -> [284, 287) features=529411 "div"
- atom [1202, 1250) -> [283, 283) features=0 ");\n__glintDSL__.noop(__glintDSL__.elementTypes[\"" <- ""
- verbatim [1250, 1253) -> [284, 287) features=66552 "div"
- atom [1253, 1264) -> [283, 283) features=0 "\"]);\nconst " <- ""
- atom [1274, 1310) -> [283, 283) features=0 " = __glintDSL__.emitElement(\"div\");\n" <- ""
- atom [1310, 1342) -> [287, 287) features=0 "__glintDSL__.applyTagAttributes(" <- ""
- atom [1342, 1352) -> [288, 288) features=0 "__glintY__" <- ""
- atom [1352, 1356) -> [287, 287) features=0 ", {\n" <- ""
- verbatim [1356, 1358) -> [288, 290) features=727039 "id"
- atom [1358, 1360) -> [288, 288) features=0 ": " <- ""
- atom [1360, 1389) -> [293, 300) features=0 "__glintDSL__.resolveOrReturn(" <- "groupId"
- verbatim [1389, 1396) -> [293, 300) features=727039 "groupId"
- atom [1396, 1397) -> [293, 300) features=0 ")" <- "groupId"
- atom [1397, 1399) -> [291, 291) features=0 "()" <- ""
- atom [1399, 1401) -> [288, 288) features=0 ",\n" <- ""
- atom [1401, 1405) -> [287, 287) features=0 "});\n" <- ""
- atom [1405, 1407) -> [283, 283) features=0 "}\n" <- ""
- atom [1407, 1413) -> [321, 321) features=0 "if (!(" <- ""
- atom [1413, 1431) -> [331, 331) features=0 "__glintRef__.args." <- ""
- verbatim [1431, 1441) -> [332, 342) features=727039 "isReadOnly"
- atom [1441, 1448) -> [321, 321) features=0 ")) {\n}\n" <- ""
- atom [1448, 1450) -> [272, 272) features=0 "}\n" <- ""
- atom [1450, 1496) -> [377, 377) features=0 "{\n__glintDSL__.noop(__glintDSL__.elementTypes." <- ""
- verbatim [1496, 1499) -> [378, 381) features=529411 "div"
- atom [1499, 1547) -> [377, 377) features=0 ");\n__glintDSL__.noop(__glintDSL__.elementTypes[\"" <- ""
- verbatim [1547, 1550) -> [378, 381) features=66552 "div"
- atom [1550, 1561) -> [377, 377) features=0 "\"]);\nconst " <- ""
- atom [1571, 1607) -> [377, 377) features=0 " = __glintDSL__.emitElement(\"div\");\n" <- ""
- atom [1607, 1653) -> [388, 388) features=0 "{\n__glintDSL__.noop(__glintDSL__.elementTypes." <- ""
- verbatim [1653, 1656) -> [389, 392) features=529411 "div"
- atom [1656, 1704) -> [388, 388) features=0 ");\n__glintDSL__.noop(__glintDSL__.elementTypes[\"" <- ""
- verbatim [1704, 1707) -> [389, 392) features=66552 "div"
- atom [1707, 1718) -> [388, 388) features=0 "\"]);\nconst " <- ""
- atom [1728, 1764) -> [388, 388) features=0 " = __glintDSL__.emitElement(\"div\");\n" <- ""
- atom [1764, 1772) -> [400, 400) features=0 "{\nconst " <- ""
- atom [1782, 1812) -> [400, 400) features=0 " = __glintDSL__.emitComponent(" <- ""
- atom [1812, 1833) -> [403, 407) features=0 "__glintDSL__.resolve(" <- "each"
- atom [1833, 1854) -> [403, 407) features=0 "__glintDSL__.Globals." <- "each"
- verbatim [1854, 1858) -> [403, 407) features=727039 "each"
- atom [1858, 1859) -> [403, 407) features=0 ")" <- "each"
- atom [1859, 1860) -> [400, 400) features=0 "(" <- ""
- atom [1860, 1878) -> [408, 408) features=0 "__glintRef__.args." <- ""
- verbatim [1878, 1883) -> [409, 414) features=727039 "items"
- atom [1883, 1884) -> [400, 400) features=0 ")" <- ""
- atom [1884, 1896) -> [400, 400) features=0 ");\n{\nconst [" <- ""
- verbatim [1896, 1907) -> [419, 430) features=727039 "allowedTeam"
- atom [1907, 1946) -> [400, 400) features=0 "] = __glintY__.blockParams[\"default\"];\n" <- ""
- atom [1946, 1992) -> [441, 441) features=0 "{\n__glintDSL__.noop(__glintDSL__.elementTypes." <- ""
- verbatim [1992, 1995) -> [442, 445) features=529411 "div"
- atom [1995, 2043) -> [441, 441) features=0 ");\n__glintDSL__.noop(__glintDSL__.elementTypes[\"" <- ""
- verbatim [2043, 2046) -> [442, 445) features=66552 "div"
- atom [2046, 2057) -> [441, 441) features=0 "\"]);\nconst " <- ""
- atom [2067, 2103) -> [441, 441) features=0 " = __glintDSL__.emitElement(\"div\");\n" <- ""
- atom [2103, 2149) -> [455, 455) features=0 "{\n__glintDSL__.noop(__glintDSL__.elementTypes." <- ""
- verbatim [2149, 2152) -> [456, 459) features=529411 "div"
- atom [2152, 2200) -> [455, 455) features=0 ");\n__glintDSL__.noop(__glintDSL__.elementTypes[\"" <- ""
- verbatim [2200, 2203) -> [456, 459) features=66552 "div"
- atom [2203, 2214) -> [455, 455) features=0 "\"]);\nconst " <- ""
- atom [2224, 2260) -> [455, 455) features=0 " = __glintDSL__.emitElement(\"div\");\n" <- ""
- atom [2260, 2306) -> [470, 470) features=0 "{\n__glintDSL__.noop(__glintDSL__.elementTypes." <- ""
- verbatim [2306, 2309) -> [471, 474) features=529411 "div"
- atom [2309, 2357) -> [470, 470) features=0 ");\n__glintDSL__.noop(__glintDSL__.elementTypes[\"" <- ""
- verbatim [2357, 2360) -> [471, 474) features=66552 "div"
- atom [2360, 2371) -> [470, 470) features=0 "\"]);\nconst " <- ""
- atom [2381, 2417) -> [470, 470) features=0 " = __glintDSL__.emitElement(\"div\");\n" <- ""
- atom [2417, 2449) -> [474, 474) features=0 "__glintDSL__.applyTagAttributes(" <- ""
- atom [2449, 2459) -> [475, 475) features=0 "__glintY__" <- ""
- atom [2459, 2463) -> [474, 474) features=0 ", {\n" <- ""
- atom [2463, 2464) -> [475, 475) features=0 "\"" <- ""
- verbatim [2464, 2470) -> [475, 481) features=727039 "data-x"
- atom [2470, 2473) -> [475, 475) features=0 "\": " <- ""
- atom [2473, 2502) -> [484, 484) features=0 "__glintDSL__.resolveOrReturn(" <- ""
- verbatim [2502, 2513) -> [484, 495) features=727039 "allowedTeam"
- atom [2513, 2515) -> [484, 484) features=0 "?." <- ""
- verbatim [2515, 2517) -> [496, 498) features=727039 "id"
- atom [2517, 2518) -> [484, 484) features=0 ")" <- ""
- atom [2518, 2520) -> [482, 482) features=0 "()" <- ""
- atom [2520, 2522) -> [475, 475) features=0 ",\n" <- ""
- atom [2522, 2526) -> [474, 474) features=0 "});\n" <- ""
- atom [2526, 2528) -> [470, 470) features=0 "}\n" <- ""
- atom [2528, 2534) -> [527, 527) features=0 "if (!(" <- ""
- atom [2534, 2552) -> [537, 537) features=0 "__glintRef__.args." <- ""
- verbatim [2552, 2562) -> [538, 548) features=727039 "isReadOnly"
- atom [2562, 2569) -> [527, 527) features=0 ")) {\n}\n" <- ""
- atom [2569, 2571) -> [455, 455) features=0 "}\n" <- ""
- atom [2571, 2573) -> [441, 441) features=0 "}\n" <- ""
- atom [2573, 2577) -> [608, 608) features=0 "if (" <- ""
- atom [2577, 2595) -> [614, 614) features=0 "__glintRef__.args." <- ""
- verbatim [2595, 2605) -> [615, 625) features=727039 "isReadOnly"
- atom [2605, 2611) -> [608, 608) features=0 ") {\n}\n" <- ""
- atom [2611, 2634) -> [400, 400) features=0 "}\n__glintDSL__.Globals." <- ""
- verbatim [2634, 2638) -> [652, 656) features=727039 "each"
- atom [2638, 2641) -> [400, 400) features=0 ";\n}" <- ""
- atom [2641, 2642) -> [388, 388) features=0 "\n" <- ""
- atom [2642, 2644) -> [388, 388) features=0 "}\n" <- ""
- atom [2644, 2646) -> [377, 377) features=0 "}\n" <- ""
- atom [2646, 2648) -> [220, 220) features=0 "}\n" <- ""
- atom [2648, 2671) -> [155, 155) features=0 "}\n__glintDSL__.Globals." <- ""
- verbatim [2671, 2674) -> [697, 700) features=727039 "let"
- atom [2674, 2677) -> [155, 155) features=0 ";\n}" <- ""
- atom [2677, 2678) -> [152, 152) features=0 "\n" <- ""
- atom [2678, 2710) -> [142, 142) features=0 "__glintRef__; __glintDSL__;\n}) }" <- ""
- verbatim [2710, 2713) -> [715, 718) features=all "\n}\n"

## Diagnostic directives

- ignore [221, 224) "div" over [700, 703) "div"
- ignore [221, 224) "div" over [751, 754) "div"
- ignore [273, 276) "div" over [1042, 1045) "div"
- ignore [273, 276) "div" over [1093, 1096) "div"
- ignore [284, 287) "div" over [1199, 1202) "div"
- ignore [284, 287) "div" over [1250, 1253) "div"
- ignore [378, 381) "div" over [1496, 1499) "div"
- ignore [378, 381) "div" over [1547, 1550) "div"
- ignore [389, 392) "div" over [1653, 1656) "div"
- ignore [389, 392) "div" over [1704, 1707) "div"
- ignore [442, 445) "div" over [1992, 1995) "div"
- ignore [442, 445) "div" over [2043, 2046) "div"
- ignore [456, 459) "div" over [2149, 2152) "div"
- ignore [456, 459) "div" over [2200, 2203) "div"
- ignore [471, 474) "div" over [2306, 2309) "div"
- ignore [471, 474) "div" over [2357, 2360) "div"

## Diagnostics

