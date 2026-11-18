/* Rebuild with .agents/tools/build-host-record-validator.cjs.
The MIT License (MIT)

Copyright (c) 2015-2021 Evgeny Poberezkin

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/
"use strict";
var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// dist/runtime/ucs2length.js
var require_ucs2length = __commonJS({
  "dist/runtime/ucs2length.js"(exports2) {
    "use strict";
    Object.defineProperty(exports2, "__esModule", { value: true });
    function ucs2length(str) {
      const len = str.length;
      let length = 0;
      let pos = 0;
      let value;
      while (pos < len) {
        length++;
        value = str.charCodeAt(pos++);
        if (value >= 55296 && value <= 56319 && pos < len) {
          value = str.charCodeAt(pos);
          if ((value & 64512) === 56320)
            pos++;
        }
      }
      return length;
    }
    exports2.default = ucs2length;
    ucs2length.code = 'require("ajv/dist/runtime/ucs2length").default';
  }
});

// <stdin>
module.exports = validate20;
module.exports.default = validate20;
var schema31 = { "$schema": "https://json-schema.org/draft/2020-12/schema", "title": "AI Host Kit host record v1", "description": "Owned by AI Host Kit. Describes one tool and changes through a pull request the person merges. Null checks and empty rollback targets mean evidence is missing, including for an adopted tool. Schema validity does not prove a live host is safe.", "type": "object", "properties": { "schema_version": { "const": "1.0" }, "tool": { "type": "string", "minLength": 1, "pattern": "^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$" }, "recipe": { "type": "string", "minLength": 1, "pattern": "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$" }, "place": { "type": "string", "minLength": 1, "pattern": "^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$" }, "address": { "anyOf": [{ "type": "string", "minLength": 1, "pattern": "^(?![\\s\\S]*\\s)https://[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?(?::[0-9]{1,5})?(?:/[A-Za-z0-9._~/-]*)?$" }, { "type": "null" }] }, "health_address": { "anyOf": [{ "type": "string", "minLength": 1, "pattern": "^(?![\\s\\S]*\\s)https://[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?(?::[0-9]{1,5})?(?:/[A-Za-z0-9._~/-]*)?$" }, { "type": "null" }] }, "deploys_on_merge": { "type": "boolean" }, "services": { "type": "array", "items": { "type": "object", "properties": { "name": { "type": "string", "minLength": 1, "pattern": "^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$" }, "kind": { "type": "string", "minLength": 1, "pattern": "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$" }, "version": { "type": "string", "minLength": 1, "pattern": "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$" }, "region": { "type": "string", "minLength": 1, "pattern": "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$" } }, "required": ["name", "kind", "version", "region"], "additionalProperties": false } }, "rollback_targets": { "type": "array", "items": { "type": "object", "properties": { "release": { "type": "string", "minLength": 1, "pattern": "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$" }, "image": { "type": "string", "minLength": 1, "pattern": "^(?![\\s\\S]*\\s)[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)*(?::[0-9]{1,5})?/[a-z0-9]+(?:[._-][a-z0-9]+)*(?:/[a-z0-9]+(?:[._-][a-z0-9]+)*)*(?::[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}|@sha256:[0-9a-f]{64})$" }, "database_compatibility": { "type": "string", "minLength": 1, "pattern": "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$" } }, "required": ["release", "image", "database_compatibility"], "additionalProperties": false } }, "last_backup_check": { "anyOf": [{ "type": "object", "properties": { "at": { "type": "string", "minLength": 1, "format": "date-time" }, "result": { "type": "string", "enum": ["passed", "failed"] }, "evidence": { "type": "string", "minLength": 1, "pattern": "^(?![\\s\\S]*\\s)(?:https://[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?(?::[0-9]{1,5})?(?:/[A-Za-z0-9._~/-]*)?|(?!.*(?:^|/)\\.{1,2}(?:/|$))[A-Za-z0-9_~-][A-Za-z0-9._~/-]*)$" } }, "required": ["at", "result", "evidence"], "additionalProperties": false }, { "type": "null" }] }, "last_restore_drill": { "anyOf": [{ "type": "object", "properties": { "at": { "type": "string", "minLength": 1, "format": "date-time" }, "result": { "type": "string", "enum": ["passed", "failed"] }, "evidence": { "type": "string", "minLength": 1, "pattern": "^(?![\\s\\S]*\\s)(?:https://[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?(?::[0-9]{1,5})?(?:/[A-Za-z0-9._~/-]*)?|(?!.*(?:^|/)\\.{1,2}(?:/|$))[A-Za-z0-9_~-][A-Za-z0-9._~/-]*)$" }, "duration_hours": { "type": "number", "minimum": 0 } }, "required": ["at", "result", "evidence", "duration_hours"], "additionalProperties": false }, { "type": "null" }] }, "fit": { "type": "string", "enum": ["fits", "gaps", "unassessed"] }, "gaps": { "type": "array", "items": { "type": "object", "properties": { "field": { "type": "string", "minLength": 1, "pattern": "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$" }, "reason": { "type": "string", "minLength": 1, "pattern": "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$" }, "status": { "type": "string", "enum": ["open", "accepted"] }, "acceptance": { "type": "object", "properties": { "words": { "type": "string", "minLength": 1, "pattern": "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$" }, "by": { "type": "string", "minLength": 1, "pattern": "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$" }, "at": { "type": "string", "minLength": 1, "format": "date-time" } }, "required": ["words", "by", "at"], "additionalProperties": false } }, "required": ["field", "reason", "status"], "additionalProperties": false, "allOf": [{ "if": { "properties": { "status": { "const": "accepted" } } }, "then": { "required": ["acceptance"] }, "else": { "properties": { "acceptance": false } } }] } } }, "required": ["schema_version", "tool", "recipe", "place", "address", "health_address", "deploys_on_merge", "services", "rollback_targets", "last_backup_check", "last_restore_drill", "fit", "gaps"], "additionalProperties": false };
var func1 = Object.prototype.hasOwnProperty;
var func2 = require_ucs2length().default;
var pattern4 = new RegExp("^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$", "u");
var pattern5 = new RegExp("^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$", "u");
var pattern7 = new RegExp("^(?![\\s\\S]*\\s)https://[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?(?::[0-9]{1,5})?(?:/[A-Za-z0-9._~/-]*)?$", "u");
var pattern14 = new RegExp("^(?![\\s\\S]*\\s)[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)*(?::[0-9]{1,5})?/[a-z0-9]+(?:[._-][a-z0-9]+)*(?:/[a-z0-9]+(?:[._-][a-z0-9]+)*)*(?::[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}|@sha256:[0-9a-f]{64})$", "u");
var pattern16 = new RegExp("^(?![\\s\\S]*\\s)(?:https://[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?(?::[0-9]{1,5})?(?:/[A-Za-z0-9._~/-]*)?|(?!.*(?:^|/)\\.{1,2}(?:/|$))[A-Za-z0-9_~-][A-Za-z0-9._~/-]*)$", "u");
var formats0 = { "date-time": function timestamp(value) {
  if (typeof value !== "string") return true;
  const match = /^(\d{4})-(\d\d)-(\d\d)[Tt](\d\d):(\d\d):(\d\d)(?:\.\d+)?(?:[Zz]|[+-](\d\d):(\d\d))$/.exec(value);
  if (!match) return false;
  const [, y, m, d, h, min, s, zh, zm] = match.map((part) => part === void 0 ? 0 : Number(part));
  const days = [31, y % 4 === 0 && (y % 100 !== 0 || y % 400 === 0) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  return y > 0 && m >= 1 && m <= 12 && d >= 1 && d <= days[m - 1] && h < 24 && min < 60 && s < 60 && zh < 24 && zm < 60;
} }["date-time"];
function validate20(data, { instancePath = "", parentData, parentDataProperty, rootData = data, dynamicAnchors = {} } = {}) {
  let vErrors = null;
  let errors = 0;
  const evaluated0 = validate20.evaluated;
  if (evaluated0.dynamicProps) {
    evaluated0.props = void 0;
  }
  if (evaluated0.dynamicItems) {
    evaluated0.items = void 0;
  }
  if (data && typeof data == "object" && !Array.isArray(data)) {
    if (data.schema_version === void 0) {
      const err0 = { instancePath, schemaPath: "#/required", keyword: "required", params: { missingProperty: "schema_version" }, message: "must have required property 'schema_version'" };
      if (vErrors === null) {
        vErrors = [err0];
      } else {
        vErrors.push(err0);
      }
      errors++;
    }
    if (data.tool === void 0) {
      const err1 = { instancePath, schemaPath: "#/required", keyword: "required", params: { missingProperty: "tool" }, message: "must have required property 'tool'" };
      if (vErrors === null) {
        vErrors = [err1];
      } else {
        vErrors.push(err1);
      }
      errors++;
    }
    if (data.recipe === void 0) {
      const err2 = { instancePath, schemaPath: "#/required", keyword: "required", params: { missingProperty: "recipe" }, message: "must have required property 'recipe'" };
      if (vErrors === null) {
        vErrors = [err2];
      } else {
        vErrors.push(err2);
      }
      errors++;
    }
    if (data.place === void 0) {
      const err3 = { instancePath, schemaPath: "#/required", keyword: "required", params: { missingProperty: "place" }, message: "must have required property 'place'" };
      if (vErrors === null) {
        vErrors = [err3];
      } else {
        vErrors.push(err3);
      }
      errors++;
    }
    if (data.address === void 0) {
      const err4 = { instancePath, schemaPath: "#/required", keyword: "required", params: { missingProperty: "address" }, message: "must have required property 'address'" };
      if (vErrors === null) {
        vErrors = [err4];
      } else {
        vErrors.push(err4);
      }
      errors++;
    }
    if (data.health_address === void 0) {
      const err5 = { instancePath, schemaPath: "#/required", keyword: "required", params: { missingProperty: "health_address" }, message: "must have required property 'health_address'" };
      if (vErrors === null) {
        vErrors = [err5];
      } else {
        vErrors.push(err5);
      }
      errors++;
    }
    if (data.deploys_on_merge === void 0) {
      const err6 = { instancePath, schemaPath: "#/required", keyword: "required", params: { missingProperty: "deploys_on_merge" }, message: "must have required property 'deploys_on_merge'" };
      if (vErrors === null) {
        vErrors = [err6];
      } else {
        vErrors.push(err6);
      }
      errors++;
    }
    if (data.services === void 0) {
      const err7 = { instancePath, schemaPath: "#/required", keyword: "required", params: { missingProperty: "services" }, message: "must have required property 'services'" };
      if (vErrors === null) {
        vErrors = [err7];
      } else {
        vErrors.push(err7);
      }
      errors++;
    }
    if (data.rollback_targets === void 0) {
      const err8 = { instancePath, schemaPath: "#/required", keyword: "required", params: { missingProperty: "rollback_targets" }, message: "must have required property 'rollback_targets'" };
      if (vErrors === null) {
        vErrors = [err8];
      } else {
        vErrors.push(err8);
      }
      errors++;
    }
    if (data.last_backup_check === void 0) {
      const err9 = { instancePath, schemaPath: "#/required", keyword: "required", params: { missingProperty: "last_backup_check" }, message: "must have required property 'last_backup_check'" };
      if (vErrors === null) {
        vErrors = [err9];
      } else {
        vErrors.push(err9);
      }
      errors++;
    }
    if (data.last_restore_drill === void 0) {
      const err10 = { instancePath, schemaPath: "#/required", keyword: "required", params: { missingProperty: "last_restore_drill" }, message: "must have required property 'last_restore_drill'" };
      if (vErrors === null) {
        vErrors = [err10];
      } else {
        vErrors.push(err10);
      }
      errors++;
    }
    if (data.fit === void 0) {
      const err11 = { instancePath, schemaPath: "#/required", keyword: "required", params: { missingProperty: "fit" }, message: "must have required property 'fit'" };
      if (vErrors === null) {
        vErrors = [err11];
      } else {
        vErrors.push(err11);
      }
      errors++;
    }
    if (data.gaps === void 0) {
      const err12 = { instancePath, schemaPath: "#/required", keyword: "required", params: { missingProperty: "gaps" }, message: "must have required property 'gaps'" };
      if (vErrors === null) {
        vErrors = [err12];
      } else {
        vErrors.push(err12);
      }
      errors++;
    }
    for (const key0 in data) {
      if (!func1.call(schema31.properties, key0)) {
        const err13 = { instancePath, schemaPath: "#/additionalProperties", keyword: "additionalProperties", params: { additionalProperty: key0 }, message: "must NOT have additional properties" };
        if (vErrors === null) {
          vErrors = [err13];
        } else {
          vErrors.push(err13);
        }
        errors++;
      }
    }
    if (data.schema_version !== void 0) {
      if ("1.0" !== data.schema_version) {
        const err14 = { instancePath: instancePath + "/schema_version", schemaPath: "#/properties/schema_version/const", keyword: "const", params: { allowedValue: "1.0" }, message: "must be equal to constant" };
        if (vErrors === null) {
          vErrors = [err14];
        } else {
          vErrors.push(err14);
        }
        errors++;
      }
    }
    if (data.tool !== void 0) {
      let data1 = data.tool;
      if (typeof data1 === "string") {
        if (func2(data1) < 1) {
          const err15 = { instancePath: instancePath + "/tool", schemaPath: "#/properties/tool/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
          if (vErrors === null) {
            vErrors = [err15];
          } else {
            vErrors.push(err15);
          }
          errors++;
        }
        if (!pattern4.test(data1)) {
          const err16 = { instancePath: instancePath + "/tool", schemaPath: "#/properties/tool/pattern", keyword: "pattern", params: { pattern: "^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$" }, message: 'must match pattern "^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$"' };
          if (vErrors === null) {
            vErrors = [err16];
          } else {
            vErrors.push(err16);
          }
          errors++;
        }
      } else {
        const err17 = { instancePath: instancePath + "/tool", schemaPath: "#/properties/tool/type", keyword: "type", params: { type: "string" }, message: "must be string" };
        if (vErrors === null) {
          vErrors = [err17];
        } else {
          vErrors.push(err17);
        }
        errors++;
      }
    }
    if (data.recipe !== void 0) {
      let data2 = data.recipe;
      if (typeof data2 === "string") {
        if (func2(data2) < 1) {
          const err18 = { instancePath: instancePath + "/recipe", schemaPath: "#/properties/recipe/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
          if (vErrors === null) {
            vErrors = [err18];
          } else {
            vErrors.push(err18);
          }
          errors++;
        }
        if (!pattern5.test(data2)) {
          const err19 = { instancePath: instancePath + "/recipe", schemaPath: "#/properties/recipe/pattern", keyword: "pattern", params: { pattern: "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$" }, message: 'must match pattern "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$"' };
          if (vErrors === null) {
            vErrors = [err19];
          } else {
            vErrors.push(err19);
          }
          errors++;
        }
      } else {
        const err20 = { instancePath: instancePath + "/recipe", schemaPath: "#/properties/recipe/type", keyword: "type", params: { type: "string" }, message: "must be string" };
        if (vErrors === null) {
          vErrors = [err20];
        } else {
          vErrors.push(err20);
        }
        errors++;
      }
    }
    if (data.place !== void 0) {
      let data3 = data.place;
      if (typeof data3 === "string") {
        if (func2(data3) < 1) {
          const err21 = { instancePath: instancePath + "/place", schemaPath: "#/properties/place/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
          if (vErrors === null) {
            vErrors = [err21];
          } else {
            vErrors.push(err21);
          }
          errors++;
        }
        if (!pattern4.test(data3)) {
          const err22 = { instancePath: instancePath + "/place", schemaPath: "#/properties/place/pattern", keyword: "pattern", params: { pattern: "^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$" }, message: 'must match pattern "^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$"' };
          if (vErrors === null) {
            vErrors = [err22];
          } else {
            vErrors.push(err22);
          }
          errors++;
        }
      } else {
        const err23 = { instancePath: instancePath + "/place", schemaPath: "#/properties/place/type", keyword: "type", params: { type: "string" }, message: "must be string" };
        if (vErrors === null) {
          vErrors = [err23];
        } else {
          vErrors.push(err23);
        }
        errors++;
      }
    }
    if (data.address !== void 0) {
      let data4 = data.address;
      const _errs10 = errors;
      let valid1 = false;
      const _errs11 = errors;
      if (typeof data4 === "string") {
        if (func2(data4) < 1) {
          const err24 = { instancePath: instancePath + "/address", schemaPath: "#/properties/address/anyOf/0/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
          if (vErrors === null) {
            vErrors = [err24];
          } else {
            vErrors.push(err24);
          }
          errors++;
        }
        if (!pattern7.test(data4)) {
          const err25 = { instancePath: instancePath + "/address", schemaPath: "#/properties/address/anyOf/0/pattern", keyword: "pattern", params: { pattern: "^(?![\\s\\S]*\\s)https://[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?(?::[0-9]{1,5})?(?:/[A-Za-z0-9._~/-]*)?$" }, message: 'must match pattern "^(?![\\s\\S]*\\s)https://[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?(?::[0-9]{1,5})?(?:/[A-Za-z0-9._~/-]*)?$"' };
          if (vErrors === null) {
            vErrors = [err25];
          } else {
            vErrors.push(err25);
          }
          errors++;
        }
      } else {
        const err26 = { instancePath: instancePath + "/address", schemaPath: "#/properties/address/anyOf/0/type", keyword: "type", params: { type: "string" }, message: "must be string" };
        if (vErrors === null) {
          vErrors = [err26];
        } else {
          vErrors.push(err26);
        }
        errors++;
      }
      var _valid0 = _errs11 === errors;
      valid1 = valid1 || _valid0;
      const _errs13 = errors;
      if (data4 !== null) {
        const err27 = { instancePath: instancePath + "/address", schemaPath: "#/properties/address/anyOf/1/type", keyword: "type", params: { type: "null" }, message: "must be null" };
        if (vErrors === null) {
          vErrors = [err27];
        } else {
          vErrors.push(err27);
        }
        errors++;
      }
      var _valid0 = _errs13 === errors;
      valid1 = valid1 || _valid0;
      if (!valid1) {
        const err28 = { instancePath: instancePath + "/address", schemaPath: "#/properties/address/anyOf", keyword: "anyOf", params: {}, message: "must match a schema in anyOf" };
        if (vErrors === null) {
          vErrors = [err28];
        } else {
          vErrors.push(err28);
        }
        errors++;
      } else {
        errors = _errs10;
        if (vErrors !== null) {
          if (_errs10) {
            vErrors.length = _errs10;
          } else {
            vErrors = null;
          }
        }
      }
    }
    if (data.health_address !== void 0) {
      let data5 = data.health_address;
      const _errs16 = errors;
      let valid2 = false;
      const _errs17 = errors;
      if (typeof data5 === "string") {
        if (func2(data5) < 1) {
          const err29 = { instancePath: instancePath + "/health_address", schemaPath: "#/properties/health_address/anyOf/0/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
          if (vErrors === null) {
            vErrors = [err29];
          } else {
            vErrors.push(err29);
          }
          errors++;
        }
        if (!pattern7.test(data5)) {
          const err30 = { instancePath: instancePath + "/health_address", schemaPath: "#/properties/health_address/anyOf/0/pattern", keyword: "pattern", params: { pattern: "^(?![\\s\\S]*\\s)https://[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?(?::[0-9]{1,5})?(?:/[A-Za-z0-9._~/-]*)?$" }, message: 'must match pattern "^(?![\\s\\S]*\\s)https://[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?(?::[0-9]{1,5})?(?:/[A-Za-z0-9._~/-]*)?$"' };
          if (vErrors === null) {
            vErrors = [err30];
          } else {
            vErrors.push(err30);
          }
          errors++;
        }
      } else {
        const err31 = { instancePath: instancePath + "/health_address", schemaPath: "#/properties/health_address/anyOf/0/type", keyword: "type", params: { type: "string" }, message: "must be string" };
        if (vErrors === null) {
          vErrors = [err31];
        } else {
          vErrors.push(err31);
        }
        errors++;
      }
      var _valid1 = _errs17 === errors;
      valid2 = valid2 || _valid1;
      const _errs19 = errors;
      if (data5 !== null) {
        const err32 = { instancePath: instancePath + "/health_address", schemaPath: "#/properties/health_address/anyOf/1/type", keyword: "type", params: { type: "null" }, message: "must be null" };
        if (vErrors === null) {
          vErrors = [err32];
        } else {
          vErrors.push(err32);
        }
        errors++;
      }
      var _valid1 = _errs19 === errors;
      valid2 = valid2 || _valid1;
      if (!valid2) {
        const err33 = { instancePath: instancePath + "/health_address", schemaPath: "#/properties/health_address/anyOf", keyword: "anyOf", params: {}, message: "must match a schema in anyOf" };
        if (vErrors === null) {
          vErrors = [err33];
        } else {
          vErrors.push(err33);
        }
        errors++;
      } else {
        errors = _errs16;
        if (vErrors !== null) {
          if (_errs16) {
            vErrors.length = _errs16;
          } else {
            vErrors = null;
          }
        }
      }
    }
    if (data.deploys_on_merge !== void 0) {
      if (typeof data.deploys_on_merge !== "boolean") {
        const err34 = { instancePath: instancePath + "/deploys_on_merge", schemaPath: "#/properties/deploys_on_merge/type", keyword: "type", params: { type: "boolean" }, message: "must be boolean" };
        if (vErrors === null) {
          vErrors = [err34];
        } else {
          vErrors.push(err34);
        }
        errors++;
      }
    }
    if (data.services !== void 0) {
      let data7 = data.services;
      if (Array.isArray(data7)) {
        const len0 = data7.length;
        for (let i0 = 0; i0 < len0; i0++) {
          let data8 = data7[i0];
          if (data8 && typeof data8 == "object" && !Array.isArray(data8)) {
            if (data8.name === void 0) {
              const err35 = { instancePath: instancePath + "/services/" + i0, schemaPath: "#/properties/services/items/required", keyword: "required", params: { missingProperty: "name" }, message: "must have required property 'name'" };
              if (vErrors === null) {
                vErrors = [err35];
              } else {
                vErrors.push(err35);
              }
              errors++;
            }
            if (data8.kind === void 0) {
              const err36 = { instancePath: instancePath + "/services/" + i0, schemaPath: "#/properties/services/items/required", keyword: "required", params: { missingProperty: "kind" }, message: "must have required property 'kind'" };
              if (vErrors === null) {
                vErrors = [err36];
              } else {
                vErrors.push(err36);
              }
              errors++;
            }
            if (data8.version === void 0) {
              const err37 = { instancePath: instancePath + "/services/" + i0, schemaPath: "#/properties/services/items/required", keyword: "required", params: { missingProperty: "version" }, message: "must have required property 'version'" };
              if (vErrors === null) {
                vErrors = [err37];
              } else {
                vErrors.push(err37);
              }
              errors++;
            }
            if (data8.region === void 0) {
              const err38 = { instancePath: instancePath + "/services/" + i0, schemaPath: "#/properties/services/items/required", keyword: "required", params: { missingProperty: "region" }, message: "must have required property 'region'" };
              if (vErrors === null) {
                vErrors = [err38];
              } else {
                vErrors.push(err38);
              }
              errors++;
            }
            for (const key1 in data8) {
              if (!(key1 === "name" || key1 === "kind" || key1 === "version" || key1 === "region")) {
                const err39 = { instancePath: instancePath + "/services/" + i0, schemaPath: "#/properties/services/items/additionalProperties", keyword: "additionalProperties", params: { additionalProperty: key1 }, message: "must NOT have additional properties" };
                if (vErrors === null) {
                  vErrors = [err39];
                } else {
                  vErrors.push(err39);
                }
                errors++;
              }
            }
            if (data8.name !== void 0) {
              let data9 = data8.name;
              if (typeof data9 === "string") {
                if (func2(data9) < 1) {
                  const err40 = { instancePath: instancePath + "/services/" + i0 + "/name", schemaPath: "#/properties/services/items/properties/name/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
                  if (vErrors === null) {
                    vErrors = [err40];
                  } else {
                    vErrors.push(err40);
                  }
                  errors++;
                }
                if (!pattern4.test(data9)) {
                  const err41 = { instancePath: instancePath + "/services/" + i0 + "/name", schemaPath: "#/properties/services/items/properties/name/pattern", keyword: "pattern", params: { pattern: "^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$" }, message: 'must match pattern "^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$"' };
                  if (vErrors === null) {
                    vErrors = [err41];
                  } else {
                    vErrors.push(err41);
                  }
                  errors++;
                }
              } else {
                const err42 = { instancePath: instancePath + "/services/" + i0 + "/name", schemaPath: "#/properties/services/items/properties/name/type", keyword: "type", params: { type: "string" }, message: "must be string" };
                if (vErrors === null) {
                  vErrors = [err42];
                } else {
                  vErrors.push(err42);
                }
                errors++;
              }
            }
            if (data8.kind !== void 0) {
              let data10 = data8.kind;
              if (typeof data10 === "string") {
                if (func2(data10) < 1) {
                  const err43 = { instancePath: instancePath + "/services/" + i0 + "/kind", schemaPath: "#/properties/services/items/properties/kind/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
                  if (vErrors === null) {
                    vErrors = [err43];
                  } else {
                    vErrors.push(err43);
                  }
                  errors++;
                }
                if (!pattern5.test(data10)) {
                  const err44 = { instancePath: instancePath + "/services/" + i0 + "/kind", schemaPath: "#/properties/services/items/properties/kind/pattern", keyword: "pattern", params: { pattern: "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$" }, message: 'must match pattern "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$"' };
                  if (vErrors === null) {
                    vErrors = [err44];
                  } else {
                    vErrors.push(err44);
                  }
                  errors++;
                }
              } else {
                const err45 = { instancePath: instancePath + "/services/" + i0 + "/kind", schemaPath: "#/properties/services/items/properties/kind/type", keyword: "type", params: { type: "string" }, message: "must be string" };
                if (vErrors === null) {
                  vErrors = [err45];
                } else {
                  vErrors.push(err45);
                }
                errors++;
              }
            }
            if (data8.version !== void 0) {
              let data11 = data8.version;
              if (typeof data11 === "string") {
                if (func2(data11) < 1) {
                  const err46 = { instancePath: instancePath + "/services/" + i0 + "/version", schemaPath: "#/properties/services/items/properties/version/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
                  if (vErrors === null) {
                    vErrors = [err46];
                  } else {
                    vErrors.push(err46);
                  }
                  errors++;
                }
                if (!pattern5.test(data11)) {
                  const err47 = { instancePath: instancePath + "/services/" + i0 + "/version", schemaPath: "#/properties/services/items/properties/version/pattern", keyword: "pattern", params: { pattern: "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$" }, message: 'must match pattern "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$"' };
                  if (vErrors === null) {
                    vErrors = [err47];
                  } else {
                    vErrors.push(err47);
                  }
                  errors++;
                }
              } else {
                const err48 = { instancePath: instancePath + "/services/" + i0 + "/version", schemaPath: "#/properties/services/items/properties/version/type", keyword: "type", params: { type: "string" }, message: "must be string" };
                if (vErrors === null) {
                  vErrors = [err48];
                } else {
                  vErrors.push(err48);
                }
                errors++;
              }
            }
            if (data8.region !== void 0) {
              let data12 = data8.region;
              if (typeof data12 === "string") {
                if (func2(data12) < 1) {
                  const err49 = { instancePath: instancePath + "/services/" + i0 + "/region", schemaPath: "#/properties/services/items/properties/region/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
                  if (vErrors === null) {
                    vErrors = [err49];
                  } else {
                    vErrors.push(err49);
                  }
                  errors++;
                }
                if (!pattern5.test(data12)) {
                  const err50 = { instancePath: instancePath + "/services/" + i0 + "/region", schemaPath: "#/properties/services/items/properties/region/pattern", keyword: "pattern", params: { pattern: "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$" }, message: 'must match pattern "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$"' };
                  if (vErrors === null) {
                    vErrors = [err50];
                  } else {
                    vErrors.push(err50);
                  }
                  errors++;
                }
              } else {
                const err51 = { instancePath: instancePath + "/services/" + i0 + "/region", schemaPath: "#/properties/services/items/properties/region/type", keyword: "type", params: { type: "string" }, message: "must be string" };
                if (vErrors === null) {
                  vErrors = [err51];
                } else {
                  vErrors.push(err51);
                }
                errors++;
              }
            }
          } else {
            const err52 = { instancePath: instancePath + "/services/" + i0, schemaPath: "#/properties/services/items/type", keyword: "type", params: { type: "object" }, message: "must be object" };
            if (vErrors === null) {
              vErrors = [err52];
            } else {
              vErrors.push(err52);
            }
            errors++;
          }
        }
      } else {
        const err53 = { instancePath: instancePath + "/services", schemaPath: "#/properties/services/type", keyword: "type", params: { type: "array" }, message: "must be array" };
        if (vErrors === null) {
          vErrors = [err53];
        } else {
          vErrors.push(err53);
        }
        errors++;
      }
    }
    if (data.rollback_targets !== void 0) {
      let data13 = data.rollback_targets;
      if (Array.isArray(data13)) {
        const len1 = data13.length;
        for (let i1 = 0; i1 < len1; i1++) {
          let data14 = data13[i1];
          if (data14 && typeof data14 == "object" && !Array.isArray(data14)) {
            if (data14.release === void 0) {
              const err54 = { instancePath: instancePath + "/rollback_targets/" + i1, schemaPath: "#/properties/rollback_targets/items/required", keyword: "required", params: { missingProperty: "release" }, message: "must have required property 'release'" };
              if (vErrors === null) {
                vErrors = [err54];
              } else {
                vErrors.push(err54);
              }
              errors++;
            }
            if (data14.image === void 0) {
              const err55 = { instancePath: instancePath + "/rollback_targets/" + i1, schemaPath: "#/properties/rollback_targets/items/required", keyword: "required", params: { missingProperty: "image" }, message: "must have required property 'image'" };
              if (vErrors === null) {
                vErrors = [err55];
              } else {
                vErrors.push(err55);
              }
              errors++;
            }
            if (data14.database_compatibility === void 0) {
              const err56 = { instancePath: instancePath + "/rollback_targets/" + i1, schemaPath: "#/properties/rollback_targets/items/required", keyword: "required", params: { missingProperty: "database_compatibility" }, message: "must have required property 'database_compatibility'" };
              if (vErrors === null) {
                vErrors = [err56];
              } else {
                vErrors.push(err56);
              }
              errors++;
            }
            for (const key2 in data14) {
              if (!(key2 === "release" || key2 === "image" || key2 === "database_compatibility")) {
                const err57 = { instancePath: instancePath + "/rollback_targets/" + i1, schemaPath: "#/properties/rollback_targets/items/additionalProperties", keyword: "additionalProperties", params: { additionalProperty: key2 }, message: "must NOT have additional properties" };
                if (vErrors === null) {
                  vErrors = [err57];
                } else {
                  vErrors.push(err57);
                }
                errors++;
              }
            }
            if (data14.release !== void 0) {
              let data15 = data14.release;
              if (typeof data15 === "string") {
                if (func2(data15) < 1) {
                  const err58 = { instancePath: instancePath + "/rollback_targets/" + i1 + "/release", schemaPath: "#/properties/rollback_targets/items/properties/release/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
                  if (vErrors === null) {
                    vErrors = [err58];
                  } else {
                    vErrors.push(err58);
                  }
                  errors++;
                }
                if (!pattern5.test(data15)) {
                  const err59 = { instancePath: instancePath + "/rollback_targets/" + i1 + "/release", schemaPath: "#/properties/rollback_targets/items/properties/release/pattern", keyword: "pattern", params: { pattern: "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$" }, message: 'must match pattern "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$"' };
                  if (vErrors === null) {
                    vErrors = [err59];
                  } else {
                    vErrors.push(err59);
                  }
                  errors++;
                }
              } else {
                const err60 = { instancePath: instancePath + "/rollback_targets/" + i1 + "/release", schemaPath: "#/properties/rollback_targets/items/properties/release/type", keyword: "type", params: { type: "string" }, message: "must be string" };
                if (vErrors === null) {
                  vErrors = [err60];
                } else {
                  vErrors.push(err60);
                }
                errors++;
              }
            }
            if (data14.image !== void 0) {
              let data16 = data14.image;
              if (typeof data16 === "string") {
                if (func2(data16) < 1) {
                  const err61 = { instancePath: instancePath + "/rollback_targets/" + i1 + "/image", schemaPath: "#/properties/rollback_targets/items/properties/image/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
                  if (vErrors === null) {
                    vErrors = [err61];
                  } else {
                    vErrors.push(err61);
                  }
                  errors++;
                }
                if (!pattern14.test(data16)) {
                  const err62 = { instancePath: instancePath + "/rollback_targets/" + i1 + "/image", schemaPath: "#/properties/rollback_targets/items/properties/image/pattern", keyword: "pattern", params: { pattern: "^(?![\\s\\S]*\\s)[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)*(?::[0-9]{1,5})?/[a-z0-9]+(?:[._-][a-z0-9]+)*(?:/[a-z0-9]+(?:[._-][a-z0-9]+)*)*(?::[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}|@sha256:[0-9a-f]{64})$" }, message: 'must match pattern "^(?![\\s\\S]*\\s)[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)*(?::[0-9]{1,5})?/[a-z0-9]+(?:[._-][a-z0-9]+)*(?:/[a-z0-9]+(?:[._-][a-z0-9]+)*)*(?::[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}|@sha256:[0-9a-f]{64})$"' };
                  if (vErrors === null) {
                    vErrors = [err62];
                  } else {
                    vErrors.push(err62);
                  }
                  errors++;
                }
              } else {
                const err63 = { instancePath: instancePath + "/rollback_targets/" + i1 + "/image", schemaPath: "#/properties/rollback_targets/items/properties/image/type", keyword: "type", params: { type: "string" }, message: "must be string" };
                if (vErrors === null) {
                  vErrors = [err63];
                } else {
                  vErrors.push(err63);
                }
                errors++;
              }
            }
            if (data14.database_compatibility !== void 0) {
              let data17 = data14.database_compatibility;
              if (typeof data17 === "string") {
                if (func2(data17) < 1) {
                  const err64 = { instancePath: instancePath + "/rollback_targets/" + i1 + "/database_compatibility", schemaPath: "#/properties/rollback_targets/items/properties/database_compatibility/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
                  if (vErrors === null) {
                    vErrors = [err64];
                  } else {
                    vErrors.push(err64);
                  }
                  errors++;
                }
                if (!pattern5.test(data17)) {
                  const err65 = { instancePath: instancePath + "/rollback_targets/" + i1 + "/database_compatibility", schemaPath: "#/properties/rollback_targets/items/properties/database_compatibility/pattern", keyword: "pattern", params: { pattern: "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$" }, message: 'must match pattern "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$"' };
                  if (vErrors === null) {
                    vErrors = [err65];
                  } else {
                    vErrors.push(err65);
                  }
                  errors++;
                }
              } else {
                const err66 = { instancePath: instancePath + "/rollback_targets/" + i1 + "/database_compatibility", schemaPath: "#/properties/rollback_targets/items/properties/database_compatibility/type", keyword: "type", params: { type: "string" }, message: "must be string" };
                if (vErrors === null) {
                  vErrors = [err66];
                } else {
                  vErrors.push(err66);
                }
                errors++;
              }
            }
          } else {
            const err67 = { instancePath: instancePath + "/rollback_targets/" + i1, schemaPath: "#/properties/rollback_targets/items/type", keyword: "type", params: { type: "object" }, message: "must be object" };
            if (vErrors === null) {
              vErrors = [err67];
            } else {
              vErrors.push(err67);
            }
            errors++;
          }
        }
      } else {
        const err68 = { instancePath: instancePath + "/rollback_targets", schemaPath: "#/properties/rollback_targets/type", keyword: "type", params: { type: "array" }, message: "must be array" };
        if (vErrors === null) {
          vErrors = [err68];
        } else {
          vErrors.push(err68);
        }
        errors++;
      }
    }
    if (data.last_backup_check !== void 0) {
      let data18 = data.last_backup_check;
      const _errs48 = errors;
      let valid9 = false;
      const _errs49 = errors;
      if (data18 && typeof data18 == "object" && !Array.isArray(data18)) {
        if (data18.at === void 0) {
          const err69 = { instancePath: instancePath + "/last_backup_check", schemaPath: "#/properties/last_backup_check/anyOf/0/required", keyword: "required", params: { missingProperty: "at" }, message: "must have required property 'at'" };
          if (vErrors === null) {
            vErrors = [err69];
          } else {
            vErrors.push(err69);
          }
          errors++;
        }
        if (data18.result === void 0) {
          const err70 = { instancePath: instancePath + "/last_backup_check", schemaPath: "#/properties/last_backup_check/anyOf/0/required", keyword: "required", params: { missingProperty: "result" }, message: "must have required property 'result'" };
          if (vErrors === null) {
            vErrors = [err70];
          } else {
            vErrors.push(err70);
          }
          errors++;
        }
        if (data18.evidence === void 0) {
          const err71 = { instancePath: instancePath + "/last_backup_check", schemaPath: "#/properties/last_backup_check/anyOf/0/required", keyword: "required", params: { missingProperty: "evidence" }, message: "must have required property 'evidence'" };
          if (vErrors === null) {
            vErrors = [err71];
          } else {
            vErrors.push(err71);
          }
          errors++;
        }
        for (const key3 in data18) {
          if (!(key3 === "at" || key3 === "result" || key3 === "evidence")) {
            const err72 = { instancePath: instancePath + "/last_backup_check", schemaPath: "#/properties/last_backup_check/anyOf/0/additionalProperties", keyword: "additionalProperties", params: { additionalProperty: key3 }, message: "must NOT have additional properties" };
            if (vErrors === null) {
              vErrors = [err72];
            } else {
              vErrors.push(err72);
            }
            errors++;
          }
        }
        if (data18.at !== void 0) {
          let data19 = data18.at;
          if (typeof data19 === "string") {
            if (func2(data19) < 1) {
              const err73 = { instancePath: instancePath + "/last_backup_check/at", schemaPath: "#/properties/last_backup_check/anyOf/0/properties/at/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
              if (vErrors === null) {
                vErrors = [err73];
              } else {
                vErrors.push(err73);
              }
              errors++;
            }
            if (!formats0(data19)) {
              const err74 = { instancePath: instancePath + "/last_backup_check/at", schemaPath: "#/properties/last_backup_check/anyOf/0/properties/at/format", keyword: "format", params: { format: "date-time" }, message: 'must match format "date-time"' };
              if (vErrors === null) {
                vErrors = [err74];
              } else {
                vErrors.push(err74);
              }
              errors++;
            }
          } else {
            const err75 = { instancePath: instancePath + "/last_backup_check/at", schemaPath: "#/properties/last_backup_check/anyOf/0/properties/at/type", keyword: "type", params: { type: "string" }, message: "must be string" };
            if (vErrors === null) {
              vErrors = [err75];
            } else {
              vErrors.push(err75);
            }
            errors++;
          }
        }
        if (data18.result !== void 0) {
          let data20 = data18.result;
          if (typeof data20 !== "string") {
            const err76 = { instancePath: instancePath + "/last_backup_check/result", schemaPath: "#/properties/last_backup_check/anyOf/0/properties/result/type", keyword: "type", params: { type: "string" }, message: "must be string" };
            if (vErrors === null) {
              vErrors = [err76];
            } else {
              vErrors.push(err76);
            }
            errors++;
          }
          if (!(data20 === "passed" || data20 === "failed")) {
            const err77 = { instancePath: instancePath + "/last_backup_check/result", schemaPath: "#/properties/last_backup_check/anyOf/0/properties/result/enum", keyword: "enum", params: { allowedValues: schema31.properties.last_backup_check.anyOf[0].properties.result.enum }, message: "must be equal to one of the allowed values" };
            if (vErrors === null) {
              vErrors = [err77];
            } else {
              vErrors.push(err77);
            }
            errors++;
          }
        }
        if (data18.evidence !== void 0) {
          let data21 = data18.evidence;
          if (typeof data21 === "string") {
            if (func2(data21) < 1) {
              const err78 = { instancePath: instancePath + "/last_backup_check/evidence", schemaPath: "#/properties/last_backup_check/anyOf/0/properties/evidence/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
              if (vErrors === null) {
                vErrors = [err78];
              } else {
                vErrors.push(err78);
              }
              errors++;
            }
            if (!pattern16.test(data21)) {
              const err79 = { instancePath: instancePath + "/last_backup_check/evidence", schemaPath: "#/properties/last_backup_check/anyOf/0/properties/evidence/pattern", keyword: "pattern", params: { pattern: "^(?![\\s\\S]*\\s)(?:https://[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?(?::[0-9]{1,5})?(?:/[A-Za-z0-9._~/-]*)?|(?!.*(?:^|/)\\.{1,2}(?:/|$))[A-Za-z0-9_~-][A-Za-z0-9._~/-]*)$" }, message: 'must match pattern "^(?![\\s\\S]*\\s)(?:https://[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?(?::[0-9]{1,5})?(?:/[A-Za-z0-9._~/-]*)?|(?!.*(?:^|/)\\.{1,2}(?:/|$))[A-Za-z0-9_~-][A-Za-z0-9._~/-]*)$"' };
              if (vErrors === null) {
                vErrors = [err79];
              } else {
                vErrors.push(err79);
              }
              errors++;
            }
          } else {
            const err80 = { instancePath: instancePath + "/last_backup_check/evidence", schemaPath: "#/properties/last_backup_check/anyOf/0/properties/evidence/type", keyword: "type", params: { type: "string" }, message: "must be string" };
            if (vErrors === null) {
              vErrors = [err80];
            } else {
              vErrors.push(err80);
            }
            errors++;
          }
        }
      } else {
        const err81 = { instancePath: instancePath + "/last_backup_check", schemaPath: "#/properties/last_backup_check/anyOf/0/type", keyword: "type", params: { type: "object" }, message: "must be object" };
        if (vErrors === null) {
          vErrors = [err81];
        } else {
          vErrors.push(err81);
        }
        errors++;
      }
      var _valid2 = _errs49 === errors;
      valid9 = valid9 || _valid2;
      const _errs58 = errors;
      if (data18 !== null) {
        const err82 = { instancePath: instancePath + "/last_backup_check", schemaPath: "#/properties/last_backup_check/anyOf/1/type", keyword: "type", params: { type: "null" }, message: "must be null" };
        if (vErrors === null) {
          vErrors = [err82];
        } else {
          vErrors.push(err82);
        }
        errors++;
      }
      var _valid2 = _errs58 === errors;
      valid9 = valid9 || _valid2;
      if (!valid9) {
        const err83 = { instancePath: instancePath + "/last_backup_check", schemaPath: "#/properties/last_backup_check/anyOf", keyword: "anyOf", params: {}, message: "must match a schema in anyOf" };
        if (vErrors === null) {
          vErrors = [err83];
        } else {
          vErrors.push(err83);
        }
        errors++;
      } else {
        errors = _errs48;
        if (vErrors !== null) {
          if (_errs48) {
            vErrors.length = _errs48;
          } else {
            vErrors = null;
          }
        }
      }
    }
    if (data.last_restore_drill !== void 0) {
      let data22 = data.last_restore_drill;
      const _errs61 = errors;
      let valid11 = false;
      const _errs62 = errors;
      if (data22 && typeof data22 == "object" && !Array.isArray(data22)) {
        if (data22.at === void 0) {
          const err84 = { instancePath: instancePath + "/last_restore_drill", schemaPath: "#/properties/last_restore_drill/anyOf/0/required", keyword: "required", params: { missingProperty: "at" }, message: "must have required property 'at'" };
          if (vErrors === null) {
            vErrors = [err84];
          } else {
            vErrors.push(err84);
          }
          errors++;
        }
        if (data22.result === void 0) {
          const err85 = { instancePath: instancePath + "/last_restore_drill", schemaPath: "#/properties/last_restore_drill/anyOf/0/required", keyword: "required", params: { missingProperty: "result" }, message: "must have required property 'result'" };
          if (vErrors === null) {
            vErrors = [err85];
          } else {
            vErrors.push(err85);
          }
          errors++;
        }
        if (data22.evidence === void 0) {
          const err86 = { instancePath: instancePath + "/last_restore_drill", schemaPath: "#/properties/last_restore_drill/anyOf/0/required", keyword: "required", params: { missingProperty: "evidence" }, message: "must have required property 'evidence'" };
          if (vErrors === null) {
            vErrors = [err86];
          } else {
            vErrors.push(err86);
          }
          errors++;
        }
        if (data22.duration_hours === void 0) {
          const err87 = { instancePath: instancePath + "/last_restore_drill", schemaPath: "#/properties/last_restore_drill/anyOf/0/required", keyword: "required", params: { missingProperty: "duration_hours" }, message: "must have required property 'duration_hours'" };
          if (vErrors === null) {
            vErrors = [err87];
          } else {
            vErrors.push(err87);
          }
          errors++;
        }
        for (const key4 in data22) {
          if (!(key4 === "at" || key4 === "result" || key4 === "evidence" || key4 === "duration_hours")) {
            const err88 = { instancePath: instancePath + "/last_restore_drill", schemaPath: "#/properties/last_restore_drill/anyOf/0/additionalProperties", keyword: "additionalProperties", params: { additionalProperty: key4 }, message: "must NOT have additional properties" };
            if (vErrors === null) {
              vErrors = [err88];
            } else {
              vErrors.push(err88);
            }
            errors++;
          }
        }
        if (data22.at !== void 0) {
          let data23 = data22.at;
          if (typeof data23 === "string") {
            if (func2(data23) < 1) {
              const err89 = { instancePath: instancePath + "/last_restore_drill/at", schemaPath: "#/properties/last_restore_drill/anyOf/0/properties/at/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
              if (vErrors === null) {
                vErrors = [err89];
              } else {
                vErrors.push(err89);
              }
              errors++;
            }
            if (!formats0(data23)) {
              const err90 = { instancePath: instancePath + "/last_restore_drill/at", schemaPath: "#/properties/last_restore_drill/anyOf/0/properties/at/format", keyword: "format", params: { format: "date-time" }, message: 'must match format "date-time"' };
              if (vErrors === null) {
                vErrors = [err90];
              } else {
                vErrors.push(err90);
              }
              errors++;
            }
          } else {
            const err91 = { instancePath: instancePath + "/last_restore_drill/at", schemaPath: "#/properties/last_restore_drill/anyOf/0/properties/at/type", keyword: "type", params: { type: "string" }, message: "must be string" };
            if (vErrors === null) {
              vErrors = [err91];
            } else {
              vErrors.push(err91);
            }
            errors++;
          }
        }
        if (data22.result !== void 0) {
          let data24 = data22.result;
          if (typeof data24 !== "string") {
            const err92 = { instancePath: instancePath + "/last_restore_drill/result", schemaPath: "#/properties/last_restore_drill/anyOf/0/properties/result/type", keyword: "type", params: { type: "string" }, message: "must be string" };
            if (vErrors === null) {
              vErrors = [err92];
            } else {
              vErrors.push(err92);
            }
            errors++;
          }
          if (!(data24 === "passed" || data24 === "failed")) {
            const err93 = { instancePath: instancePath + "/last_restore_drill/result", schemaPath: "#/properties/last_restore_drill/anyOf/0/properties/result/enum", keyword: "enum", params: { allowedValues: schema31.properties.last_restore_drill.anyOf[0].properties.result.enum }, message: "must be equal to one of the allowed values" };
            if (vErrors === null) {
              vErrors = [err93];
            } else {
              vErrors.push(err93);
            }
            errors++;
          }
        }
        if (data22.evidence !== void 0) {
          let data25 = data22.evidence;
          if (typeof data25 === "string") {
            if (func2(data25) < 1) {
              const err94 = { instancePath: instancePath + "/last_restore_drill/evidence", schemaPath: "#/properties/last_restore_drill/anyOf/0/properties/evidence/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
              if (vErrors === null) {
                vErrors = [err94];
              } else {
                vErrors.push(err94);
              }
              errors++;
            }
            if (!pattern16.test(data25)) {
              const err95 = { instancePath: instancePath + "/last_restore_drill/evidence", schemaPath: "#/properties/last_restore_drill/anyOf/0/properties/evidence/pattern", keyword: "pattern", params: { pattern: "^(?![\\s\\S]*\\s)(?:https://[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?(?::[0-9]{1,5})?(?:/[A-Za-z0-9._~/-]*)?|(?!.*(?:^|/)\\.{1,2}(?:/|$))[A-Za-z0-9_~-][A-Za-z0-9._~/-]*)$" }, message: 'must match pattern "^(?![\\s\\S]*\\s)(?:https://[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?(?::[0-9]{1,5})?(?:/[A-Za-z0-9._~/-]*)?|(?!.*(?:^|/)\\.{1,2}(?:/|$))[A-Za-z0-9_~-][A-Za-z0-9._~/-]*)$"' };
              if (vErrors === null) {
                vErrors = [err95];
              } else {
                vErrors.push(err95);
              }
              errors++;
            }
          } else {
            const err96 = { instancePath: instancePath + "/last_restore_drill/evidence", schemaPath: "#/properties/last_restore_drill/anyOf/0/properties/evidence/type", keyword: "type", params: { type: "string" }, message: "must be string" };
            if (vErrors === null) {
              vErrors = [err96];
            } else {
              vErrors.push(err96);
            }
            errors++;
          }
        }
        if (data22.duration_hours !== void 0) {
          let data26 = data22.duration_hours;
          if (typeof data26 == "number" && isFinite(data26)) {
            if (data26 < 0 || isNaN(data26)) {
              const err97 = { instancePath: instancePath + "/last_restore_drill/duration_hours", schemaPath: "#/properties/last_restore_drill/anyOf/0/properties/duration_hours/minimum", keyword: "minimum", params: { comparison: ">=", limit: 0 }, message: "must be >= 0" };
              if (vErrors === null) {
                vErrors = [err97];
              } else {
                vErrors.push(err97);
              }
              errors++;
            }
          } else {
            const err98 = { instancePath: instancePath + "/last_restore_drill/duration_hours", schemaPath: "#/properties/last_restore_drill/anyOf/0/properties/duration_hours/type", keyword: "type", params: { type: "number" }, message: "must be number" };
            if (vErrors === null) {
              vErrors = [err98];
            } else {
              vErrors.push(err98);
            }
            errors++;
          }
        }
      } else {
        const err99 = { instancePath: instancePath + "/last_restore_drill", schemaPath: "#/properties/last_restore_drill/anyOf/0/type", keyword: "type", params: { type: "object" }, message: "must be object" };
        if (vErrors === null) {
          vErrors = [err99];
        } else {
          vErrors.push(err99);
        }
        errors++;
      }
      var _valid3 = _errs62 === errors;
      valid11 = valid11 || _valid3;
      const _errs73 = errors;
      if (data22 !== null) {
        const err100 = { instancePath: instancePath + "/last_restore_drill", schemaPath: "#/properties/last_restore_drill/anyOf/1/type", keyword: "type", params: { type: "null" }, message: "must be null" };
        if (vErrors === null) {
          vErrors = [err100];
        } else {
          vErrors.push(err100);
        }
        errors++;
      }
      var _valid3 = _errs73 === errors;
      valid11 = valid11 || _valid3;
      if (!valid11) {
        const err101 = { instancePath: instancePath + "/last_restore_drill", schemaPath: "#/properties/last_restore_drill/anyOf", keyword: "anyOf", params: {}, message: "must match a schema in anyOf" };
        if (vErrors === null) {
          vErrors = [err101];
        } else {
          vErrors.push(err101);
        }
        errors++;
      } else {
        errors = _errs61;
        if (vErrors !== null) {
          if (_errs61) {
            vErrors.length = _errs61;
          } else {
            vErrors = null;
          }
        }
      }
    }
    if (data.fit !== void 0) {
      let data27 = data.fit;
      if (typeof data27 !== "string") {
        const err102 = { instancePath: instancePath + "/fit", schemaPath: "#/properties/fit/type", keyword: "type", params: { type: "string" }, message: "must be string" };
        if (vErrors === null) {
          vErrors = [err102];
        } else {
          vErrors.push(err102);
        }
        errors++;
      }
      if (!(data27 === "fits" || data27 === "gaps" || data27 === "unassessed")) {
        const err103 = { instancePath: instancePath + "/fit", schemaPath: "#/properties/fit/enum", keyword: "enum", params: { allowedValues: schema31.properties.fit.enum }, message: "must be equal to one of the allowed values" };
        if (vErrors === null) {
          vErrors = [err103];
        } else {
          vErrors.push(err103);
        }
        errors++;
      }
    }
    if (data.gaps !== void 0) {
      let data28 = data.gaps;
      if (Array.isArray(data28)) {
        const len2 = data28.length;
        for (let i2 = 0; i2 < len2; i2++) {
          let data29 = data28[i2];
          const _errs82 = errors;
          let valid16 = true;
          const _errs83 = errors;
          if (data29 && typeof data29 == "object" && !Array.isArray(data29)) {
            if (data29.status !== void 0) {
              if ("accepted" !== data29.status) {
                const err104 = {};
                if (vErrors === null) {
                  vErrors = [err104];
                } else {
                  vErrors.push(err104);
                }
                errors++;
              }
            }
          }
          var _valid4 = _errs83 === errors;
          errors = _errs82;
          if (vErrors !== null) {
            if (_errs82) {
              vErrors.length = _errs82;
            } else {
              vErrors = null;
            }
          }
          let ifClause0;
          if (_valid4) {
            const _errs85 = errors;
            if (data29 && typeof data29 == "object" && !Array.isArray(data29)) {
              if (data29.acceptance === void 0) {
                const err105 = { instancePath: instancePath + "/gaps/" + i2, schemaPath: "#/properties/gaps/items/allOf/0/then/required", keyword: "required", params: { missingProperty: "acceptance" }, message: "must have required property 'acceptance'" };
                if (vErrors === null) {
                  vErrors = [err105];
                } else {
                  vErrors.push(err105);
                }
                errors++;
              }
            }
            var _valid4 = _errs85 === errors;
            valid16 = _valid4;
            ifClause0 = "then";
          } else {
            const _errs86 = errors;
            if (data29 && typeof data29 == "object" && !Array.isArray(data29)) {
              if (data29.acceptance !== void 0) {
                const err106 = { instancePath: instancePath + "/gaps/" + i2 + "/acceptance", schemaPath: "#/properties/gaps/items/allOf/0/else/properties/acceptance/false schema", keyword: "false schema", params: {}, message: "boolean schema is false" };
                if (vErrors === null) {
                  vErrors = [err106];
                } else {
                  vErrors.push(err106);
                }
                errors++;
              }
            }
            var _valid4 = _errs86 === errors;
            valid16 = _valid4;
            if (valid16) {
              var props2 = {};
              props2.acceptance = true;
              props2.status = true;
            }
            ifClause0 = "else";
          }
          if (!valid16) {
            const err107 = { instancePath: instancePath + "/gaps/" + i2, schemaPath: "#/properties/gaps/items/allOf/0/if", keyword: "if", params: { failingKeyword: ifClause0 }, message: 'must match "' + ifClause0 + '" schema' };
            if (vErrors === null) {
              vErrors = [err107];
            } else {
              vErrors.push(err107);
            }
            errors++;
          }
          if (data29 && typeof data29 == "object" && !Array.isArray(data29)) {
            if (data29.field === void 0) {
              const err108 = { instancePath: instancePath + "/gaps/" + i2, schemaPath: "#/properties/gaps/items/required", keyword: "required", params: { missingProperty: "field" }, message: "must have required property 'field'" };
              if (vErrors === null) {
                vErrors = [err108];
              } else {
                vErrors.push(err108);
              }
              errors++;
            }
            if (data29.reason === void 0) {
              const err109 = { instancePath: instancePath + "/gaps/" + i2, schemaPath: "#/properties/gaps/items/required", keyword: "required", params: { missingProperty: "reason" }, message: "must have required property 'reason'" };
              if (vErrors === null) {
                vErrors = [err109];
              } else {
                vErrors.push(err109);
              }
              errors++;
            }
            if (data29.status === void 0) {
              const err110 = { instancePath: instancePath + "/gaps/" + i2, schemaPath: "#/properties/gaps/items/required", keyword: "required", params: { missingProperty: "status" }, message: "must have required property 'status'" };
              if (vErrors === null) {
                vErrors = [err110];
              } else {
                vErrors.push(err110);
              }
              errors++;
            }
            for (const key5 in data29) {
              if (!(key5 === "field" || key5 === "reason" || key5 === "status" || key5 === "acceptance")) {
                const err111 = { instancePath: instancePath + "/gaps/" + i2, schemaPath: "#/properties/gaps/items/additionalProperties", keyword: "additionalProperties", params: { additionalProperty: key5 }, message: "must NOT have additional properties" };
                if (vErrors === null) {
                  vErrors = [err111];
                } else {
                  vErrors.push(err111);
                }
                errors++;
              }
            }
            if (data29.field !== void 0) {
              let data32 = data29.field;
              if (typeof data32 === "string") {
                if (func2(data32) < 1) {
                  const err112 = { instancePath: instancePath + "/gaps/" + i2 + "/field", schemaPath: "#/properties/gaps/items/properties/field/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
                  if (vErrors === null) {
                    vErrors = [err112];
                  } else {
                    vErrors.push(err112);
                  }
                  errors++;
                }
                if (!pattern5.test(data32)) {
                  const err113 = { instancePath: instancePath + "/gaps/" + i2 + "/field", schemaPath: "#/properties/gaps/items/properties/field/pattern", keyword: "pattern", params: { pattern: "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$" }, message: 'must match pattern "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$"' };
                  if (vErrors === null) {
                    vErrors = [err113];
                  } else {
                    vErrors.push(err113);
                  }
                  errors++;
                }
              } else {
                const err114 = { instancePath: instancePath + "/gaps/" + i2 + "/field", schemaPath: "#/properties/gaps/items/properties/field/type", keyword: "type", params: { type: "string" }, message: "must be string" };
                if (vErrors === null) {
                  vErrors = [err114];
                } else {
                  vErrors.push(err114);
                }
                errors++;
              }
            }
            if (data29.reason !== void 0) {
              let data33 = data29.reason;
              if (typeof data33 === "string") {
                if (func2(data33) < 1) {
                  const err115 = { instancePath: instancePath + "/gaps/" + i2 + "/reason", schemaPath: "#/properties/gaps/items/properties/reason/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
                  if (vErrors === null) {
                    vErrors = [err115];
                  } else {
                    vErrors.push(err115);
                  }
                  errors++;
                }
                if (!pattern5.test(data33)) {
                  const err116 = { instancePath: instancePath + "/gaps/" + i2 + "/reason", schemaPath: "#/properties/gaps/items/properties/reason/pattern", keyword: "pattern", params: { pattern: "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$" }, message: 'must match pattern "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$"' };
                  if (vErrors === null) {
                    vErrors = [err116];
                  } else {
                    vErrors.push(err116);
                  }
                  errors++;
                }
              } else {
                const err117 = { instancePath: instancePath + "/gaps/" + i2 + "/reason", schemaPath: "#/properties/gaps/items/properties/reason/type", keyword: "type", params: { type: "string" }, message: "must be string" };
                if (vErrors === null) {
                  vErrors = [err117];
                } else {
                  vErrors.push(err117);
                }
                errors++;
              }
            }
            if (data29.status !== void 0) {
              let data34 = data29.status;
              if (typeof data34 !== "string") {
                const err118 = { instancePath: instancePath + "/gaps/" + i2 + "/status", schemaPath: "#/properties/gaps/items/properties/status/type", keyword: "type", params: { type: "string" }, message: "must be string" };
                if (vErrors === null) {
                  vErrors = [err118];
                } else {
                  vErrors.push(err118);
                }
                errors++;
              }
              if (!(data34 === "open" || data34 === "accepted")) {
                const err119 = { instancePath: instancePath + "/gaps/" + i2 + "/status", schemaPath: "#/properties/gaps/items/properties/status/enum", keyword: "enum", params: { allowedValues: schema31.properties.gaps.items.properties.status.enum }, message: "must be equal to one of the allowed values" };
                if (vErrors === null) {
                  vErrors = [err119];
                } else {
                  vErrors.push(err119);
                }
                errors++;
              }
            }
            if (data29.acceptance !== void 0) {
              let data35 = data29.acceptance;
              if (data35 && typeof data35 == "object" && !Array.isArray(data35)) {
                if (data35.words === void 0) {
                  const err120 = { instancePath: instancePath + "/gaps/" + i2 + "/acceptance", schemaPath: "#/properties/gaps/items/properties/acceptance/required", keyword: "required", params: { missingProperty: "words" }, message: "must have required property 'words'" };
                  if (vErrors === null) {
                    vErrors = [err120];
                  } else {
                    vErrors.push(err120);
                  }
                  errors++;
                }
                if (data35.by === void 0) {
                  const err121 = { instancePath: instancePath + "/gaps/" + i2 + "/acceptance", schemaPath: "#/properties/gaps/items/properties/acceptance/required", keyword: "required", params: { missingProperty: "by" }, message: "must have required property 'by'" };
                  if (vErrors === null) {
                    vErrors = [err121];
                  } else {
                    vErrors.push(err121);
                  }
                  errors++;
                }
                if (data35.at === void 0) {
                  const err122 = { instancePath: instancePath + "/gaps/" + i2 + "/acceptance", schemaPath: "#/properties/gaps/items/properties/acceptance/required", keyword: "required", params: { missingProperty: "at" }, message: "must have required property 'at'" };
                  if (vErrors === null) {
                    vErrors = [err122];
                  } else {
                    vErrors.push(err122);
                  }
                  errors++;
                }
                for (const key6 in data35) {
                  if (!(key6 === "words" || key6 === "by" || key6 === "at")) {
                    const err123 = { instancePath: instancePath + "/gaps/" + i2 + "/acceptance", schemaPath: "#/properties/gaps/items/properties/acceptance/additionalProperties", keyword: "additionalProperties", params: { additionalProperty: key6 }, message: "must NOT have additional properties" };
                    if (vErrors === null) {
                      vErrors = [err123];
                    } else {
                      vErrors.push(err123);
                    }
                    errors++;
                  }
                }
                if (data35.words !== void 0) {
                  let data36 = data35.words;
                  if (typeof data36 === "string") {
                    if (func2(data36) < 1) {
                      const err124 = { instancePath: instancePath + "/gaps/" + i2 + "/acceptance/words", schemaPath: "#/properties/gaps/items/properties/acceptance/properties/words/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
                      if (vErrors === null) {
                        vErrors = [err124];
                      } else {
                        vErrors.push(err124);
                      }
                      errors++;
                    }
                    if (!pattern5.test(data36)) {
                      const err125 = { instancePath: instancePath + "/gaps/" + i2 + "/acceptance/words", schemaPath: "#/properties/gaps/items/properties/acceptance/properties/words/pattern", keyword: "pattern", params: { pattern: "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$" }, message: 'must match pattern "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$"' };
                      if (vErrors === null) {
                        vErrors = [err125];
                      } else {
                        vErrors.push(err125);
                      }
                      errors++;
                    }
                  } else {
                    const err126 = { instancePath: instancePath + "/gaps/" + i2 + "/acceptance/words", schemaPath: "#/properties/gaps/items/properties/acceptance/properties/words/type", keyword: "type", params: { type: "string" }, message: "must be string" };
                    if (vErrors === null) {
                      vErrors = [err126];
                    } else {
                      vErrors.push(err126);
                    }
                    errors++;
                  }
                }
                if (data35.by !== void 0) {
                  let data37 = data35.by;
                  if (typeof data37 === "string") {
                    if (func2(data37) < 1) {
                      const err127 = { instancePath: instancePath + "/gaps/" + i2 + "/acceptance/by", schemaPath: "#/properties/gaps/items/properties/acceptance/properties/by/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
                      if (vErrors === null) {
                        vErrors = [err127];
                      } else {
                        vErrors.push(err127);
                      }
                      errors++;
                    }
                    if (!pattern5.test(data37)) {
                      const err128 = { instancePath: instancePath + "/gaps/" + i2 + "/acceptance/by", schemaPath: "#/properties/gaps/items/properties/acceptance/properties/by/pattern", keyword: "pattern", params: { pattern: "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$" }, message: 'must match pattern "^(?![\\s\\S]*[A-Za-z][A-Za-z0-9+.-]*://[^\\s]*[@?#%\\\\])[\\s\\S]*$"' };
                      if (vErrors === null) {
                        vErrors = [err128];
                      } else {
                        vErrors.push(err128);
                      }
                      errors++;
                    }
                  } else {
                    const err129 = { instancePath: instancePath + "/gaps/" + i2 + "/acceptance/by", schemaPath: "#/properties/gaps/items/properties/acceptance/properties/by/type", keyword: "type", params: { type: "string" }, message: "must be string" };
                    if (vErrors === null) {
                      vErrors = [err129];
                    } else {
                      vErrors.push(err129);
                    }
                    errors++;
                  }
                }
                if (data35.at !== void 0) {
                  let data38 = data35.at;
                  if (typeof data38 === "string") {
                    if (func2(data38) < 1) {
                      const err130 = { instancePath: instancePath + "/gaps/" + i2 + "/acceptance/at", schemaPath: "#/properties/gaps/items/properties/acceptance/properties/at/minLength", keyword: "minLength", params: { limit: 1 }, message: "must NOT have fewer than 1 characters" };
                      if (vErrors === null) {
                        vErrors = [err130];
                      } else {
                        vErrors.push(err130);
                      }
                      errors++;
                    }
                    if (!formats0(data38)) {
                      const err131 = { instancePath: instancePath + "/gaps/" + i2 + "/acceptance/at", schemaPath: "#/properties/gaps/items/properties/acceptance/properties/at/format", keyword: "format", params: { format: "date-time" }, message: 'must match format "date-time"' };
                      if (vErrors === null) {
                        vErrors = [err131];
                      } else {
                        vErrors.push(err131);
                      }
                      errors++;
                    }
                  } else {
                    const err132 = { instancePath: instancePath + "/gaps/" + i2 + "/acceptance/at", schemaPath: "#/properties/gaps/items/properties/acceptance/properties/at/type", keyword: "type", params: { type: "string" }, message: "must be string" };
                    if (vErrors === null) {
                      vErrors = [err132];
                    } else {
                      vErrors.push(err132);
                    }
                    errors++;
                  }
                }
              } else {
                const err133 = { instancePath: instancePath + "/gaps/" + i2 + "/acceptance", schemaPath: "#/properties/gaps/items/properties/acceptance/type", keyword: "type", params: { type: "object" }, message: "must be object" };
                if (vErrors === null) {
                  vErrors = [err133];
                } else {
                  vErrors.push(err133);
                }
                errors++;
              }
            }
          } else {
            const err134 = { instancePath: instancePath + "/gaps/" + i2, schemaPath: "#/properties/gaps/items/type", keyword: "type", params: { type: "object" }, message: "must be object" };
            if (vErrors === null) {
              vErrors = [err134];
            } else {
              vErrors.push(err134);
            }
            errors++;
          }
        }
      } else {
        const err135 = { instancePath: instancePath + "/gaps", schemaPath: "#/properties/gaps/type", keyword: "type", params: { type: "array" }, message: "must be array" };
        if (vErrors === null) {
          vErrors = [err135];
        } else {
          vErrors.push(err135);
        }
        errors++;
      }
    }
  } else {
    const err136 = { instancePath, schemaPath: "#/type", keyword: "type", params: { type: "object" }, message: "must be object" };
    if (vErrors === null) {
      vErrors = [err136];
    } else {
      vErrors.push(err136);
    }
    errors++;
  }
  validate20.errors = vErrors;
  return errors === 0;
}
validate20.evaluated = { "props": true, "dynamicProps": false, "dynamicItems": false };
